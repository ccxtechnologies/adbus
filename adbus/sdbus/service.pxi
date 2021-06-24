# Copyright: 2017-2021, CCX Technologies
#cython: language_level=3

cdef class Service:
    cdef sdbus_h.sd_bus *bus
    cdef bytes name
    cdef bytes unique_name
    cdef bool connected
    cdef bool process_loop
    cdef stdint.uint64_t flags
    cdef object loop
    cdef object startup_task

    def __cinit__(self, name=None, loop=None, bus='system',
            replace_existing=False, allow_replacement=False, queue=False):
        cdef const char *unique

        if name:
            self.name = name.encode()
        else:
            self.name = b''
        self.flags = 0
        self.connected = False
        self.loop = loop

        if bus == 'system':
            if sdbus_h.sd_bus_open_system(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        elif bus == 'session':
            if sdbus_h.sd_bus_open_user(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        else:
            raise BusError(f"Invalid bus {bus}, expecting system of session")

        if replace_existing:
            self.flags |= sdbus_h.SD_BUS_NAME_REPLACE_EXISTING

        if allow_replacement:
            self.flags |= sdbus_h.SD_BUS_NAME_ALLOW_REPLACEMENT

        if queue:
            self.flags |= sdbus_h.SD_BUS_NAME_QUEUE

        if self.name:
            if sdbus_h.sd_bus_request_name(self.bus, self.name, self.flags) < 0:
                raise BusError(f"Failed to acquire name {self.name.decode('utf-8')}")

        if sdbus_h.sd_bus_get_unique_name(self.bus, &unique) < 0:
            raise BusError("Failed to read unique name")
        self.unique_name = unique

        bus_fd = sdbus_h.sd_bus_get_fd(self.bus)
        if bus_fd <= 0:
            raise BusError("Failed to read sd-bus file descriptor")

        if not loop:
            loop = get_event_loop()

        self.process_loop = True
        self.startup_task = loop.create_task(self.startup_process())
        loop.add_reader(bus_fd, self.process)

        self.loop = loop

    def stop(self):
        self.startup_task.cancel()
        bus_fd = sdbus_h.sd_bus_get_fd(self.bus)
        if bus_fd > 0:
            self.loop.remove_reader(bus_fd)
        self.process_loop = False

        self.bus = sdbus_h.sd_bus_flush_close_unref(self.bus)

    def __enter__(self):
        return self

    def __exit__(self, exception_type, exception_value, exception_traceback):
        self.stop()

    def is_running(self):
        """Service is running."""
        return self.loop.is_running()

    def get_loop(self):
        """Get the service's asyncio loop."""
        return self.loop

    async def startup_process(self):
        self.process()

    def process(self):
        """Processes all available transactions from the D-Bus.

        Raises:
            sdbus.BusError: if an error occurs interfacing with the D-Bus
            Exception: re-raised if raised by any callbacks, or property setters
        """

        if self.connected:
            raise BusError(f"Already processing")

        self.connected = True
        try:
            while self.process_loop:
                r = sdbus_h.sd_bus_process(self.bus, NULL)

                if r < 0:
                    raise BusError(f"D-Bus Process Error: {errorcode[-r]}")

                if r == 0:
                    break

        finally:
            self.connected = False
