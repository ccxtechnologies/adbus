# == Copyright: 2017, Charles Eidsness

cdef class Service:
    cdef _sdbus_h.sd_bus *bus

    def __cinit__(self, name, system=False):

        if system:
            if _sdbus_h.sd_bus_open_system(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        else:
            if _sdbus_h.sd_bus_open_user(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        if _sdbus_h.sd_bus_request_name(self.bus, name, 0) < 0:
            raise BusError(f"Failed to acquire name {name}")

    def __dealloc__(self):
        self.bus = _sdbus_h.sd_bus_unref(self.bus)

    async def process(self):
        while True:
            if not self._bus_process():
                await self._bus_wait()

    async def _bus_wait(self):
        r = _sdbus_h.sd_bus_wait(self.bus, -1)
        if r < 0:
            raise BusError(f"Failed to wait for bus {self.name}")

    def _bus_process(self):
        r = _sdbus_h.sd_bus_process(self.bus, NULL)
        if r < 0:
            raise BusError(f"Failed to process bus {self.name}")
        return bool(r)

