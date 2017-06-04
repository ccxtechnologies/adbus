# == Copyright: 2017, Charles Eidsness

# NOTE: Bit of an issue here, ppoll sleeps the main thread so that the
#  mainloop stalls. We probably want two threads, one running process
#  which will add coroutines to the mainloop?
#    I want to get a call, and be able to sleep while processing that
#    call. Maybe I do need one thread per call. 
#   thread 1 -- wait
#   thread 2 -- process
#   thread 3 -- process
#   .....
#  ----> use a thread pool and add threads as messages come in
#  ----> use a thread pool and add threads as messages come in

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
        loop = get_event_loop()
        pool = ThreadPoolExecutor(5)
        while True:
            await loop.run_in_executor(pool, self._bus_process)
            await loop.run_in_executor(pool, self._bus_wait)

    def _bus_wait(self):
        print("Waiting")
        r = _sdbus_h.sd_bus_wait(self.bus, -1)
        if r < 0:
            raise BusError(f"Failed to wait for bus {self.name}")

    def _bus_process(self):
        print("Processing")
        r = _sdbus_h.sd_bus_process(self.bus, NULL)
        if r < 0:
            raise BusError(f"Failed to process bus {self.name}")
        return bool(r)

