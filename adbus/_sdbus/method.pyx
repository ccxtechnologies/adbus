# == Copyright: 2017, Charles Eidsness

cdef int method_message_handler(_sdbus_h.sd_bus_message *m, 
        void *userdata, _sdbus_h.sd_bus_error *err):

    cdef PyObject *method_ptr = (((<PyObject**>userdata)[0]))
    cdef Method method = <Method>method_ptr
    cdef Message message = Message()
    cdef Error error
    cdef list args

    message.import_sd_bus_message(m)
    args = message.read()
    
    try:
        ret = method.callback(*args)
    except Exception as e:
        error = Error()
        error.import_sd_bus_error(err)
        method.exceptions.append(e)
        return error.from_exception(e)

    return 0

cdef class Method:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef _sdbus_h.sd_bus_vtable_method x
    cdef void *userdata
    cdef object callback
    cdef bytes name
    cdef bytes arg_types
    cdef bytes return_type
    cdef list exceptions

    def __cinit__(self, name, callback, arg_types='', return_type='',
            deprectiated=False, hidden=False, unprivledged=False):

        self.name = name.encode()
        self.arg_types = arg_types.encode()
        self.return_type = return_type.encode()
        self.callback = callback
        self.exceptions = []
    
        self.type = _sdbus_h._SD_BUS_VTABLE_METHOD

        self.flags = 0
        if not return_type:
            self.flags |= _sdbus_h.SD_BUS_VTABLE_METHOD_NO_REPLY

        if deprectiated:
            self.flags |= _sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= _sdbus_h.SD_BUS_VTABLE_HIDDEN

        if unprivledged:
            self.flags |= _sdbus_h.SD_BUS_VTABLE_UNPRIVILEGED

        self.x.member = self.name
        self.x.handler = method_message_handler
        self.x.signature = self.arg_types
        self.x.result = self.return_type
        
        self.userdata = <void *>self
    
    cdef populate_vtable(self, _sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))
