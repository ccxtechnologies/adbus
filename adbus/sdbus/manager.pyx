# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef class Manager:
    cdef sdbus_h.sd_bus *bus
    cdef sdbus_h.sd_bus_slot *_slot
    cdef bytes path

    def __cinit__(self, service, path):
        self.path = path.encode()
        self.bus = (<Service>service).bus

        ret = sdbus_h.sd_bus_add_object_manager(self.bus, &self._slot, self.path)
        if ret < 0:
            raise SdbusError(f"Failed to add manager: {errorcode[-ret]}", -ret)

    def __dealloc__(self):
        self._slot = sdbus_h.sd_bus_slot_unref(self._slot)
