# == Copyright: 2017, CCX Technologies

cdef class Signal:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_signal x
    cdef void *userdata
    cdef bytes name
    cdef bytes signature
    cdef Object object

    def __cinit__(self, name, signature='', depreciated=False, hidden=False):

        self.name = name.encode()
        self.signature = signature.encode()
        self.type = sdbus_h._SD_BUS_VTABLE_SIGNAL
        self.object = None

        self.flags = 0
        if depreciated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        self.x.member = self.name
        self.x.signature = self.signature

    cdef populate_vtable(self, sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))

    cdef set_object(self, object):
        if self.object:
            raise SdbusError("Signal already associated")
        self.object = object

    def emit(self, value):
        message = Message()
        message.new_signal(self)
        message.append(self.signature, value)
        message.send()

