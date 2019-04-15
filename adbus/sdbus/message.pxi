# == Copyright: 2017, CCX Technologies
#cython: language_level=3

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

cdef class Message:
    cdef sdbus_h.sd_bus_message *message

    def __cinit__(self):
        self.message = NULL

    def __dealloc__(self):
        self.message = sdbus_h.sd_bus_message_unref(self.message)

    cdef import_sd_bus_message(self, sdbus_h.sd_bus_message *message):
        cdef errno
        cdef const sdbus_h.sd_bus_error *err

        err = sdbus_h.sd_bus_message_get_error(message)
        if err:
            errno = sdbus_h.sd_bus_message_get_errno(message)
            raise SdbusError(f"{err.name.decode()}: {err.message.decode()}", -errno)

        self.message = sdbus_h.sd_bus_message_unref(self.message)
        self.message = sdbus_h.sd_bus_message_ref(message)

    cdef new_method_call(self, Service service, char *destination,
            char *path, char *interface, const char *member):
        cdef int ret

        self.message = sdbus_h.sd_bus_message_unref(self.message)
        ret = sdbus_h.sd_bus_message_new_method_call(service.bus,
            &self.message, destination, path, interface, member)
        if ret < 0:
            raise SdbusError(
                f"Failed to create new method call: {errorcode[-ret]}", -ret)

    cdef new_method_return(self):
        cdef int ret
        cdef sdbus_h.sd_bus_message *call = self.message
        ret = sdbus_h.sd_bus_message_new_method_return(call, &self.message)
        if ret < 0:
            raise SdbusError(
                f"Failed to create new method return: {errorcode[-ret]}", -ret)
        sdbus_h.sd_bus_message_unref(call)

    cdef new_method_error(self, sdbus_h.sd_bus_message *call,
            Exception exception):
        cdef int ret
        self.message = sdbus_h.sd_bus_message_unref(self.message)
        ret = sdbus_h.sd_bus_message_new_method_return(call, &self.message)
        if ret < 0:
            raise SdbusError(
                f"Failed to create new method error: {errorcode[-ret]}", -ret)

    cdef new_signal(self, Signal signal):
        cdef int ret
        self.message = sdbus_h.sd_bus_message_unref(self.message)
        ret = sdbus_h.sd_bus_message_new_signal(signal.bus, &self.message,
                signal.path, signal.interface, signal.name)
        if ret < 0:
            raise SdbusError(
                f"Failed to create new signal: {errorcode[-ret]}", -ret)

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
        ret = sdbus_h.sd_bus_message_read_basic(self.message, sig, value)
        if ret < 0:
            raise SdbusError(
                    f"Failed to read value with signature {chr(sig)}: {errorcode[-ret]}",
                    -ret)

    cdef _read_array(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]])
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]] + bytes(1)
        cdef char *esignature = psignature
        cdef list values = []
        cdef list value

        index[0] += elength

        if sdbus_h.sd_bus_message_enter_container(self.message,
                sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to enter array {esignature}")

        while not sdbus_h.sd_bus_message_at_end(self.message,0):
            value = self.read(esignature)
            if len(value) == 1:
                values.append(value[0])
            else:
                values.append(value)

        if sdbus_h.sd_bus_message_exit_container(self.message) < 0:
            raise SdbusError(f"Failed to exit array {esignature}")

        # A dictionary is always an array with two elements (based on D-Bus
        # definition) so if we're a dictionary convert it.
        if esignature[0] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
            return {v[0]: v[1] for v in values}
        else:
            return values

    cdef _read_variant(self):
        cdef const char *esignature
        cdef list value

        if sdbus_h.sd_bus_message_enter_container(self.message,
                sdbus_h.SD_BUS_TYPE_VARIANT, NULL) < 0:
            raise SdbusError("Failed to enter variant")

        esignature = sdbus_h.sd_bus_message_get_signature(self.message, 0)
        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self.message) < 0:
            raise SdbusError(f"Failed to exit variant {esignature}")

        # variant only has one type
        return value[0]

    cdef tuple _read_struct(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]-1])-1
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]-1] + bytes(1)
        cdef char *esignature = psignature
        cdef list value

        index[0] += elength + 1

        if sdbus_h.sd_bus_message_enter_container(self.message,
                sdbus_h.SD_BUS_TYPE_STRUCT, esignature) < 0:
            raise SdbusError(f"Failed to enter structure {esignature}")

        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self.message) < 0:
            raise SdbusError(f"Failed to exit structure {esignature}")

        return tuple(value)

    cdef list _read_dict(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]-1])-1
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]-1] + bytes(1)
        cdef char *esignature = psignature

        index[0] += elength + 1

        if sdbus_h.sd_bus_message_enter_container(self.message,
                sdbus_h.SD_BUS_TYPE_DICT_ENTRY, esignature) < 0:
            raise SdbusError(f"Failed to enter dictionary {esignature}")

        value = self.read(esignature)

        if sdbus_h.sd_bus_message_exit_container(self.message) < 0:
            raise SdbusError(f"Failed to exit dictionary {esignature}")

        return value

    cdef list read(self, const char *signature=b"ANY"):
        cdef _value v
        cdef list values = []
        cdef unsigned int i = 0
        cdef char s

        if signature[0] == b'A':
            signature = sdbus_h.sd_bus_message_get_signature(self.message, 0)

        while i < len(signature):
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
                raise SdbusError(f"Unsupported signature type {signature} -> {chr(s)} for read")

        return values

    # ------------

    cdef _append_basic(self, char sig, const void *value):
        cdef int ret
        ret = sdbus_h.sd_bus_message_append_basic(self.message, sig, value)
        if ret < 0:
            raise SdbusError(
                    f"Failed to append value {chr(sig)}: {errorcode[-ret]}", -ret)

    cdef _append_array(self, const char *signature, object value,
            unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]])
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]] + bytes(1)
        cdef char *esignature = psignature

        index[0] += elength

        if sdbus_h.sd_bus_message_open_container(self.message,
                sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to open array {esignature}")

        for item in value:
            self.append(esignature, item)

        if sdbus_h.sd_bus_message_close_container(self.message) < 0:
            raise SdbusError(f"Failed to close array {esignature}")

    cdef _append_variant(self, object value):
        cdef bytes signature
        cdef const char *esignature

        signature = _object_signature(value)
        esignature = signature

        if sdbus_h.sd_bus_message_open_container(self.message,
                sdbus_h.SD_BUS_TYPE_VARIANT, esignature) < 0:
            raise SdbusError(f"Failed to open variant {esignature}")

        self.append(esignature, value)

        if sdbus_h.sd_bus_message_close_container(self.message) < 0:
            raise SdbusError(f"Failed to close variant {esignature}")

    cdef _append_struct(self, const char *signature, object value,
            unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]-1])-2
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]] + bytes(1)
        cdef char *esignature = psignature

        index[0] += elength + 2

        if sdbus_h.sd_bus_message_open_container(self.message,
                sdbus_h.SD_BUS_TYPE_STRUCT, esignature) < 0:
            raise SdbusError(f"Failed to open struct {psignature} {index[0]} {elength} {signature}")

        self._append_multiple(esignature, value)

        if sdbus_h.sd_bus_message_close_container(self.message) < 0:
            raise SdbusError(f"Failed to close struct {esignature}")

    cdef _append_dict(self, const char *signature, object value,
            unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]])
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[index[0]:elength+index[0]] + bytes(1)
        cdef char *esignature = psignature

        index[0] += elength

        if sdbus_h.sd_bus_message_open_container(self.message,
                sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to open dict {esignature}")

        for item in value.items():
            self._append_dict_item(esignature, item)

        if sdbus_h.sd_bus_message_close_container(self.message) < 0:
            raise SdbusError(f"Failed to close dict {esignature}")

    cdef _append_dict_item(self, const char *signature, object value):
        cdef unsigned int elength = self._element_length(&signature[2])
        cdef bytes bsignature = signature
        cdef bytes psignature = bsignature[1:2+elength] + bytes(1)
        cdef char *esignature = psignature
        cdef char ksignature = esignature[0]
        cdef char *vsignature = &esignature[1]

        if sdbus_h.sd_bus_message_open_container(self.message,
                sdbus_h.SD_BUS_TYPE_DICT_ENTRY, esignature) < 0:
            raise SdbusError(f"Failed to open dict item {esignature}")

        self.append(&ksignature, value[0])
        self.append(vsignature, value[1])

        if sdbus_h.sd_bus_message_close_container(self.message) < 0:
            raise SdbusError(f"Failed to close dict item {esignature}")

    cdef _append_multiple(self, const char *signature, object values):
        cdef unsigned int i = 0
        cdef char s
        cdef object value

        if isinstance(values, (str, bytes)):
            values = [values]
        elif isinstance(values, tuple):
            values = list(values)

        while values:
            s = signature[i]
            i += 1

            value = values.pop(0)

            try:
                value = value.dbus_value
            except AttributeError:
                pass

            if s == sdbus_h.SD_BUS_TYPE_ARRAY:
                if signature[1] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                    self._append_dict(signature, value, &i)
                else:
                    self._append_array(signature, value, &i)

            elif s == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
                self._append_struct(signature, value, &i)

            else:
                self.append(&s, value)

    cdef append(self, const char *signature, object value):
        cdef _value v
        cdef unsigned int i = 1
        cdef char s
        cdef bytes v_str

        s = signature[0]

        try:
            value = value.dbus_value
        except AttributeError:
            pass

        if s == sdbus_h._SD_BUS_TYPE_INVALID:
            return

        elif s == sdbus_h.SD_BUS_TYPE_ARRAY:
            if signature[1] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                self._append_dict(signature, value, &i)
            else:
                self._append_array(signature, value, &i)

        elif s == sdbus_h.SD_BUS_TYPE_VARIANT:
            self._append_variant(value)

        elif s == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
            self._append_struct(signature, value, &i)

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
            if type(value) == str:
                v_str = value.encode('utf-8')
                v.c_str = v_str
            else:
                try:
                    v.c_str = value
                except TypeError as e:
                    e.args = (f"expected str or bytes, {type(value).__name__} found",)
                    raise
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_OBJECT_PATH:
            if type(value) == str:
                v_str = value.encode('utf-8')
                v.c_str = v_str
            else:
                try:
                    v.c_str = value
                except TypeError as e:
                    e.args = (f"expected str or bytes, {type(value).__name__} found",)
                    raise
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_SIGNATURE:
            if type(value) == str:
                v_str = value.encode('utf-8')
                v.c_str = v_str
            else:
                try:
                    v.c_str = value
                except TypeError as e:
                    e.args = (f"expected str or bytes, {type(value).__name__} found",)
                    raise
            self._append_basic(s, <void*>v.c_str)

        elif s == sdbus_h.SD_BUS_TYPE_UNIX_FD:
            v.c_int32 = value
            self._append_basic(s, <void*>&v.c_int32)

        else:
            raise SdbusError(f"Unsupported signature type {chr(s)} for append")


    # ------------

    cdef send(self):
        cdef int ret
        ret = sdbus_h.sd_bus_send(NULL, self.message, NULL)
        if ret < 0:
            raise SdbusError(f"Failed to send message: {errorcode[-ret]}", -ret)

