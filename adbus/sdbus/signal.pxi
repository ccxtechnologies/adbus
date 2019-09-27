# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef class Signal:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_signal x
    cdef void *userdata
    cdef bytes name
    cdef list signature
    cdef bytes arg_signature
    cdef bool connected
    cdef sdbus_h.sd_bus *bus
    cdef bytes path
    cdef bytes interface

    def __cinit__(self, name, signature=(), deprecated=False, hidden=False):

        self.name = name.encode()
        self.signature = [s.encode() for s in signature]
        self.arg_signature = (''.join(signature)).encode()
        self.type = sdbus_h._SD_BUS_VTABLE_SIGNAL
        self.connected = False

        self.flags = 0
        if deprecated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        self.x.member = self.name
        self.x.signature = self.arg_signature

    cdef populate_vtable(self, sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))

    cdef set_object(self, Object object):
        if self.connected:
            raise SdbusError("Signal already associated")
        self.connected = True
        self.bus = object.bus
        self.path = object.path
        self.interface = object.interface

    def emit(self, *values):
        message = Message()
        message.new_signal(self)
        for i, value in enumerate(values):
            try:
                message.append(self.signature[i], value)
            except IndexError:
                raise SdbusError(
                        f"Signal expects {len(self.signature)} arguments "
                        f"but received {len(values)}.")
        message.send()

