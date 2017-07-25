# Copyright: 2017, CCX Technologies

cdef class Service:
    cdef sdbus_h.sd_bus *bus
    cdef bytes name
    cdef bool connected
    cdef list exceptions
    cdef stdint.uint64_t flags

    def __cinit__(self, name, bus='system',
            replace_existing=False, allow_replacement=False, queue=False):

        self.name = name.encode()
        self.exceptions = []
        self.flags = 0
        self.connected = False

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

        if sdbus_h.sd_bus_request_name(self.bus, self.name, self.flags) < 0:
            raise BusError(f"Failed to acquire name {self.name.decode('utf-8')}")

    def __dealloc__(self):
        self.bus = sdbus_h.sd_bus_unref(self.bus)

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
            while True:
                r = sdbus_h.sd_bus_process(self.bus, NULL)

                if r < 0:
                    raise BusError(f"D-Bus Process Error: {errorcode[-r]}")

                if self.exceptions:
                    for callback_exception in self.exceptions[:]:
                        self.exceptions.remove(callback_exception)
                        raise callback_exception

                if r == 0:
                    break
        finally:
            self.connected = False

    def get_fd(self):
        """Get the file-descriptor associated with the D-Bus socket.

        Returns:
            A file descriptor (int), which can be used to wait for incoming messages.
        ."""
        return sdbus_h.sd_bus_get_fd(self.bus)
