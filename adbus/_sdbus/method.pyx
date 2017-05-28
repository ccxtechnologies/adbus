# == Copyright: 2017, Charles Eidsness

cdef int method_message_handler(_sdbus_h.sd_bus_message *m, 
        void *userdata, _sdbus_h.sd_bus_error *e):
    cdef void *f = (<void**>userdata)[0]
    (<object>f)()
    return 0

cdef class Method:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef _sdbus_h.sd_bus_vtable_method x
    cdef void *userdata

    def __cinit__(self, name, callback, arg_types=b'', return_type=b'',
            deprectiated=False, hidden=False, unprivledged=False):
    
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

        self.x.member = name
        self.x.handler = method_message_handler
        self.x.signature = arg_types
        self.x.result = return_type
        
        self.userdata = <void *>callback
    
    cdef populate_vtable(self, _sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))
