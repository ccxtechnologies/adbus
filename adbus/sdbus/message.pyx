# == Copyright: 2017, Charles Eidsness

cdef union _value:
    stdint.uint8_t c_byte
    stdint.uint16_t c_uint16
    stdint.int16_t c_int16
    stdint.uint32_t c_uint32
    stdint.int32_t c_int32
    stdint.uint64_t c_uint64
    stdint.int64_t c_int64
    double c_double
    bint c_bool
    const char* c_str

cdef class MessageEmpty(Exception):
    """Empty Message Element"""
    pass

cdef class Message:
    cdef sdbus_h.sd_bus_message *_m

    def __cinit__(self):
        self._m = NULL

    def __dealloc__(self):
        self._m = sdbus_h.sd_bus_message_unref(self._m)

    # ------------

    cdef import_sd_bus_message(self, sdbus_h.sd_bus_message *message):
        self._m = sdbus_h.sd_bus_message_unref(self._m)
        self._m = sdbus_h.sd_bus_message_ref(message)

    cdef new_method_return(self, sdbus_h.sd_bus_message *call):
        cdef int ret
        self._m = sdbus_h.sd_bus_message_unref(self._m)
        ret = sdbus_h.sd_bus_message_new_method_return(call, &self._m)
        if ret < 0:
            raise SdbusError(f"New method returned: {errorcode[-ret]}", -ret)

    cdef new_signal(self, Signal signal):
        cdef int ret
        cdef Object object = signal.object
        self._m = sdbus_h.sd_bus_message_unref(self._m)
        ret = sdbus_h.sd_bus_message_new_signal(object.bus, &self._m,
                                                object.path, object.interface,
                                                signal.name)
        if ret < 0:
            raise SdbusError(f"New signal returned: {errorcode[-ret]}", -ret)

    # ------------

    cdef _element_length(self, const char *signature):
        cdef unsigned int i = 0
        cdef unsigned int scnt = 0
        cdef unsigned int dcnt = 0

        while signature[i] != 0:
            s = signature[i]
            i += 1

            if s == sdbus_h.SD_BUS_TYPE_ARRAY:
                continue
            elif s == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
                scnt += 1
            elif s == sdbus_h.SD_BUS_TYPE_STRUCT_END:
                scnt -= 1
            elif s == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                dcnt += 1
            elif s == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_END:
                dcnt -= 1

            if not dcnt and not scnt:
                break

        return i

    # ------------

    cdef _read_basic(self, char sig, void *value):
        cdef int ret
        ret = sdbus_h.sd_bus_message_read_basic(self._m, sig, value)
        if ret < 0:
            raise SdbusError(f"Failed to read value {chr(sig)}: {errorcode[-ret]}", -ret)
        if ret == 0:
            raise MessageEmpty(f"No data to read of type {chr(sig)}")

    cdef _read_array(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]])
        cdef bytes psignature = signature[index[0]:elength+index[0]] + bytes(1)
        cdef char *esignature = psignature
        cdef list values = []
        cdef list value

        index[0] += elength

        if sdbus_h.sd_bus_message_enter_container(self._m,
                sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to enter array {esignature}")

        while True:
            try:
                value = self.read(esignature)
                if len(value) == 1:
                    values.append(value[0])
                else:
                    values.append(value)
            except MessageEmpty:
                break

        if sdbus_h.sd_bus_message_exit_container(self._m) < 0:
            raise SdbusError(f"Failed to exit array {esignature}")

        # A dictionary is always an array with two elements (based on d-bus defintion)
        # so if we're a dictionary convert it.
        if esignature[0] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
            return {v[0]: v[1] for v in values}
        else:
            return values

    cdef list _read_variant(self):
        cdef const char *esignature
        cdef list value

        if sdbus_h.sd_bus_message_enter_container(self._m,
                sdbus_h.SD_BUS_TYPE_VARIANT, NULL) < 0:
            raise SdbusError("Failed to enter variant")

        esignature = sdbus_h.sd_bus_message_get_signature(self._m, 0)
        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self._m) < 0:
            raise SdbusError(f"Failed to exit variant {esignature}")

        return value

    cdef list _read_struct(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]-1])-1
        cdef bytes psignature = signature[index[0]:elength+index[0]-1] + bytes(1)
        cdef char *esignature = psignature
        cdef list value

        index[0] += elength + 1

        if sdbus_h.sd_bus_message_enter_container(self._m,
                sdbus_h.SD_BUS_TYPE_STRUCT, esignature) < 0:
            raise SdbusError(f"Failed to enter structure {esignature}")

        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self._m) < 0:
            raise SdbusError(f"Failed to exit structure {esignature}")

        return value

    cdef list _read_dict(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]-1])-1
        cdef bytes psignature = signature[index[0]:elength+index[0]-1] + bytes(1)
        cdef char *esignature = psignature

        index[0] += elength + 1

        if sdbus_h.sd_bus_message_enter_container(self._m,
                sdbus_h.SD_BUS_TYPE_DICT_ENTRY, esignature) < 0:
            raise SdbusError(f"Failed to enter dictionary {esignature}")

        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self._m) < 0:
            raise SdbusError(f"Failed to exit dictionary {esignature}")

        return value

    cdef list read(self, const char *signature):
        cdef _value v
        cdef list values = []
        cdef unsigned int i = 0
        cdef int struct_cnt = 0
        cdef int dict_cnt = 0
        cdef char s

        while True:
            s = signature[i]
            i += 1

            if s ==  sdbus_h._SD_BUS_TYPE_INVALID:
                break

            elif s == sdbus_h.SD_BUS_TYPE_ARRAY:
                values.append(self._read_array(signature, &i))

            elif s == sdbus_h.SD_BUS_TYPE_VARIANT:
                values.append(self._read_variant())

            elif s == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
                values.append(self._read_struct(signature, &i))

            elif s == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                values.append(self._read_dict(signature, &i))

            elif s == sdbus_h.SD_BUS_TYPE_BYTE:
                self._read_basic(s, <void*>&v.c_byte)
                values.append(v.c_byte)

            elif s == sdbus_h.SD_BUS_TYPE_BOOLEAN:
                self._read_basic(s, <void*>&v.c_bool)
                values.append(v.c_bool)

            elif s == sdbus_h.SD_BUS_TYPE_UINT16:
                self._read_basic(s, <void*>&v.c_uint16)
                values.append(v.c_uint16)

            elif s == sdbus_h.SD_BUS_TYPE_INT16:
                self._read_basic(s, <void*>&v.c_int16)
                values.append(v.c_int16)

            elif s == sdbus_h.SD_BUS_TYPE_UINT32:
                self._read_basic(s, <void*>&v.c_uint32)
                values.append(v.c_uint32)

            elif s == sdbus_h.SD_BUS_TYPE_INT32:
                self._read_basic(s, <void*>&v.c_int32)
                values.append(v.c_int32)

            elif s == sdbus_h.SD_BUS_TYPE_UINT64:
                self._read_basic(s, <void*>&v.c_uint64)
                values.append(v.c_uint64)

            elif s == sdbus_h.SD_BUS_TYPE_INT64:
                self._read_basic(s, <void*>&v.c_int64)
                values.append(v.c_int64)

            elif s == sdbus_h.SD_BUS_TYPE_DOUBLE:
                self._read_basic(s, <void*>&v.c_double)
                values.append(v.c_double)

            elif s == sdbus_h.SD_BUS_TYPE_STRING:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))

            elif s == sdbus_h.SD_BUS_TYPE_OBJECT_PATH:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))

            elif s == sdbus_h.SD_BUS_TYPE_SIGNATURE:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))

            elif s == sdbus_h.SD_BUS_TYPE_UNIX_FD:
                self._read_basic(s, <void*>&v.c_int32)
                values.append(v.c_int32)

            else:
                raise SdbusError(f"Unsupported signature type {chr(s)} for read")

        if len(values) == 0:
            raise MessageEmpty(f"No data read in type {signature}")
        else:
            return values

    # ------------

    cdef _append_basic(self, char sig, const void *value):
        cdef int ret
        ret = sdbus_h.sd_bus_message_append_basic(self._m, sig, value)
        if ret < 0:
            raise SdbusError(f"Failed to append value {chr(sig)}: {errorcode[-ret]}", -ret)

    cdef _append_array(self, const char *signature, object value):
        cdef unsigned int elength = self._element_length(&signature[1])
        cdef bytes psignature = signature[1:elength+1] + bytes(1)
        cdef char *esignature = psignature

        if sdbus_h.sd_bus_message_open_container(self._m,
                sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to open array {esignature}")

        # A dictionary is always an array with two elements (based on d-bus defintion)
        # so if we're a dictionary convert it.
        if esignature[0] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
            for k, v in (<dict>value).items():
                self.append(esignature, [k, v])
        else:
            for v in <list>value:
                self.append(esignature, v)

        if sdbus_h.sd_bus_message_close_container(self._m) < 0:
            raise SdbusError(f"Failed to close array {esignature}")

    cdef _append_variant(self, object value):
        cdef const char *esignature

        esignature = _object_signature(value)

        if sdbus_h.sd_bus_message_open_container(self._m,
                sdbus_h.SD_BUS_TYPE_VARIANT, esignature) < 0:
            raise SdbusError(f"Failed to open variant {esignature}")

        self.append(esignature, value)

        if sdbus_h.sd_bus_message_close_container(self._m) < 0:
            raise SdbusError(f"Failed to close variant {esignature}")

    cdef append(self, const char *signature, object value):
        cdef _value v
        cdef int struct_cnt = 0
        cdef int dict_cnt = 0
        cdef char s
        cdef bytes v_str

        s = signature[0]

        if s ==  sdbus_h._SD_BUS_TYPE_INVALID:
            raise MessageEmpty(f"No data append in type {signature}")

        elif s == sdbus_h.SD_BUS_TYPE_ARRAY:
            self._append_array(signature, value)

        elif s == sdbus_h.SD_BUS_TYPE_VARIANT:
            self._append_variant(value)

        elif s == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
            pass

        elif s == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
            pass

        elif s == sdbus_h.SD_BUS_TYPE_BYTE:
            v.c_byte = value
            self._append_basic(s, <void*>&v.c_byte)

        elif s == sdbus_h.SD_BUS_TYPE_BOOLEAN:
            v.c_bool = value
            self._append_basic(s, <void*>&v.c_bool)

        elif s == sdbus_h.SD_BUS_TYPE_UINT16:
            v.c_uint16 = value
            self._append_basic(s, <void*>&v.c_uint16)

        elif s == sdbus_h.SD_BUS_TYPE_INT16:
            v.c_int16 = value
            self._append_basic(s, <void*>&v.c_int16)

        elif s == sdbus_h.SD_BUS_TYPE_UINT32:
            v.c_uint32 = value
            self._append_basic(s, <void*>&v.c_uint32)

        elif s == sdbus_h.SD_BUS_TYPE_INT32:
            v.c_int32 = value
            self._append_basic(s, <void*>&v.c_int32)

        elif s == sdbus_h.SD_BUS_TYPE_UINT64:
            v.c_uint64 = value
            self._append_basic(s, <void*>&v.c_uint64)

        elif s == sdbus_h.SD_BUS_TYPE_INT64:
            v.c_int64 = value
            self._append_basic(s, <void*>&v.c_int64)

        elif s == sdbus_h.SD_BUS_TYPE_DOUBLE:
            v.c_double = value
            self._append_basic(s, <void*>&v.c_double)

        elif s == sdbus_h.SD_BUS_TYPE_STRING:
            v_str = value.encode('utf-8')
            v.c_str = v_str
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_OBJECT_PATH:
            v_str = value.encode('utf-8')
            v.c_str = v_str
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_SIGNATURE:
            v_str = value.encode('utf-8')
            v.c_str = v_str
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_UNIX_FD:
            v.c_int32 = value
            self._append_basic(s, <void*>&v.c_int32)

        else:
            raise SdbusError(f"Unsupported signature type {chr(s)} for append")

    # ------------

    cdef send(self):
        cdef int ret
        ret = sdbus_h.sd_bus_send(NULL, self._m, NULL)
        if ret < 0:
            raise SdbusError(f"Failed to send message: {errorcode[-ret]}", -ret)
