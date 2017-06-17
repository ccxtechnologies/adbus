# == Copyright: 2017, Charles Eidsness

cdef union _value:
    unsigned char c_byte
    unsigned short c_uint16
    short c_int16
    unsigned int c_uint32
    int c_int32
    unsigned long long c_uint64
    long long c_int64
    double c_double
    bint c_bool
    const char* c_str
    
cdef class MessageEmpty(Exception):
    """Empty Message Element"""
    pass

cdef class Message:
    cdef _sdbus_h.sd_bus_message *_m
    cdef bint owned

    def __cinit__(self):
        self.owned = True
        self._m = NULL
    
    def __dealloc__(self):
        if self.owned:
            PyMem_Free(self._m)

    cdef import_sd_bus_message(self, _sdbus_h.sd_bus_message *message):
        if self._m:
            raise SdbusError("Message already initialized")

        self.owned = False
        self._m = message

    @property
    def signature(self):
        return _sdbus_h.sd_bus_message_get_signature(self._m, 0)

    cdef _read_basic(self, char sig, void *value):
        cdef int ret
        ret = _sdbus_h.sd_bus_message_read_basic(self._m, sig, value);
        print((ret, chr(sig), <char*>value))
        if ret < 0:
            raise SdbusError(f"Failed to read value {chr(sig)}: {errorcode[-ret]}")
        if ret == 0:
            raise MessageEmpty(f"No data to read of type {chr(sig)}")

    cdef _element_length(self, const char *signature):
        cdef unsigned int i = 0
        cdef unsigned int scnt = 0
        cdef unsigned int dcnt = 0

        while signature[i] != 0:
            s = signature[i]
            i += 1

            if s == _sdbus_h.SD_BUS_TYPE_ARRAY:
                continue
            elif s == _sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
                scnt += 1
            elif s == _sdbus_h.SD_BUS_TYPE_STRUCT_END:
                scnt -= 1
            elif s == _sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                dcnt += 1
            elif s == _sdbus_h.SD_BUS_TYPE_DICT_ENTRY_END:
                dcnt -= 1

            if not dcnt and not scnt:
                break

        return i

    cdef _read_array(self, const char *signature, unsigned int *index):
        cdef unsigned int elength = self._element_length(&signature[index[0]])
        cdef bytes psignature = signature[index[0]:elength+index[0]]
        cdef char *esignature = psignature
        cdef list values = []
        cdef list value
        
        index[0] += elength
    
        if _sdbus_h.sd_bus_message_enter_container(self._m, 
                _sdbus_h.SD_BUS_TYPE_ARRAY, esignature) < 0:
            raise SdbusError(f"Failed to enter container {esignature}")

        while True:
            try:
                value = self._read_signature(esignature)
                if len(value) == 1:
                    values.append(value[0])
                else:
                    values.append(value)
            except MessageEmpty:
                break
    
        if _sdbus_h.sd_bus_message_exit_container(self._m) < 0:
            raise SdbusError(f"Failed to exit container {esignature}")

        return values

    cdef list _read_signature(self, const char *signature):
        cdef _value v
        cdef list values = []
        cdef unsigned int i = 0
        cdef int struct_cnt = 0
        cdef int dict_cnt = 0
        cdef char s

        while signature[i] != 0:
            s = signature[i]
            i += 1

            if s == _sdbus_h.SD_BUS_TYPE_ARRAY:
                values.append(self._read_array(signature, &i))

            elif s == _sdbus_h.SD_BUS_TYPE_VARIANT:
                pass

            elif s == _sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
                pass

            elif s == _sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
                pass

            elif s == _sdbus_h.SD_BUS_TYPE_BYTE:
                self._read_basic(s, <void*>&v.c_byte)
                values.append(v.c_byte)
            
            elif s == _sdbus_h.SD_BUS_TYPE_BOOLEAN:
                self._read_basic(s, <void*>&v.c_bool)
                values.append(v.c_bool)
            
            elif s == _sdbus_h.SD_BUS_TYPE_UINT16:
                self._read_basic(s, <void*>&v.c_uint16)
                values.append(v.c_uint16)
            
            elif s == _sdbus_h.SD_BUS_TYPE_INT16:
                self._read_basic(s, <void*>&v.c_int16)
                values.append(v.c_int16)
            
            elif s == _sdbus_h.SD_BUS_TYPE_UINT32:
                self._read_basic(s, <void*>&v.c_uint32)
                values.append(v.c_uint32)
            
            elif s == _sdbus_h.SD_BUS_TYPE_INT32:
                self._read_basic(s, <void*>&v.c_int32)
                values.append(v.c_int32)
            
            elif s == _sdbus_h.SD_BUS_TYPE_UINT64:
                self._read_basic(s, <void*>&v.c_uint64)
                values.append(v.c_uint64)
            
            elif s == _sdbus_h.SD_BUS_TYPE_INT64:
                self._read_basic(s, <void*>&v.c_int64)
                values.append(v.c_int64)

            elif s == _sdbus_h.SD_BUS_TYPE_DOUBLE:
                self._read_basic(s, <void*>&v.c_double)
                values.append(v.c_double)
            
            elif s == _sdbus_h.SD_BUS_TYPE_STRING:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))
            
            elif s == _sdbus_h.SD_BUS_TYPE_OBJECT_PATH:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))
            
            elif s == _sdbus_h.SD_BUS_TYPE_SIGNATURE:
                self._read_basic(s, <void*>&v.c_str)
                values.append(v.c_str.decode('utf-8'))
            
            elif s == _sdbus_h.SD_BUS_TYPE_UNIX_FD:
                self._read_basic(s, <void*>&v.c_int32)
                values.append(v.c_int32)

            else:
                raise SdbusError(f"Unsupported signature type {str(s)}")

        if len(values) == 0:
            raise MessageEmpty(f"No data read in type {signature}")
        else:
            return values
    
    cdef list read(self):
        cdef const char *signature = _sdbus_h.sd_bus_message_get_signature(self._m, 0)
        return self._read_signature(signature)

