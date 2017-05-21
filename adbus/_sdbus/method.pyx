# == Copyright: 2017, Charles Eidsness

cimport _sdbus_h
from libc cimport stdint

cdef int message_handler(_sdbus_h.sd_bus_message *m, 
        void *f, _sdbus_h.sd_bus_error *e):
    (<object>f)()
    return 0

cdef class Method:
    cdef stdint.uint64_t flags
    cdef _sdbus_h.sd_bus_vtable_method vtable
    cdef void *userdata

    def __cinit__(self, name, callback, arg_types='', return_type='',
            deprectiated=False, hidden=False, unprivledged=False):

        self.flags = _SD_BUS_VTABLE_METHOD
        if not return_type:
            self.flags |= SD_BUS_VTABLE_METHOD_NO_REPLY
        if deprectiated:
            self.flags |= SD_BUS_VTABLE_DEPRECATED
        if hidden:
            self.flags |= SD_BUS_VTABLE_HIDDEN
        if unprivledged:
            self.flags |= SD_BUS_VTABLE_UNPRIVILEGED

        self.vtable.member = name
        if arg_types:
            self.vtable.signature = arg_type
        if return_type:
            self.vtable.result = return_type
        self.vtable.handler = message_handler

        self.userdata = callback

