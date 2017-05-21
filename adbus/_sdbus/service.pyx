# == Copyright: 2017, Charles Eidsness

cdef class Service:
    cdef _sdbus_h.sd_bus *_bus

    def __cinit__(self, name, system=False):
        if system:
            if _sdbus_h.sd_bus_open_system(&self._bus) < 0:
                raise BusError("Failed to connect to Bus")

        else:
            if _sdbus_h.sd_bus_open_user(&self._bus) < 0:
                raise BusError("Failed to connect to Bus")

        if _sdbus_h.sd_bus_request_name(self._bus, name.encode('utf-8'), 0) < 0:
            raise BusError(f"Failed to acquire name {name}")

    def __dealloc__(self):
        self._bus = _sdbus_h.sd_bus_unref(self._bus)

    def process(self):
        #TODO: Replace with somethin that uses asyncio
        while True:
            r = _sdbus_h.sd_bus_process(self._bus, NULL)
            if r < 0:
                raise BusError("Failed to process bus")
            if r > 0:
                continue

            if _sdbus_h.sd_bus_wait(self._bus, -1) < 0:
                raise BusError("Failed to wait for bus")

