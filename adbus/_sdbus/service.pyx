# == Copyright: 2017, Charles Eidsness

cdef class Service:
    cdef _sdbus_h.sd_bus *bus
    cdef bytes name
    cdef list objects
    cdef list exceptions

    def __cinit__(self, name, system=False):
        self.name = name.encode()
        self.objects = []
        self.exceptions = []

        if system:
            if _sdbus_h.sd_bus_open_system(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        else:
            if _sdbus_h.sd_bus_open_user(&self.bus) < 0:
                raise BusError("Failed to connect to Bus")

        if _sdbus_h.sd_bus_request_name(self.bus, self.name, 0) < 0:
            raise BusError(f"Failed to acquire name {self.name.decode('utf-8')}")
        
    def __dealloc__(self):
        self.bus = _sdbus_h.sd_bus_unref(self.bus)

    def process(self):
        while True:
            print("processing")
            r = _sdbus_h.sd_bus_process(self.bus, NULL)

            if r < 0:
                raise BusError(f"Failed to process {self.name.decode('utf-8')}: {errorcode[-r]}")

            if self.exceptions:
                for callback_exception in self.exceptions[:]:
                    self.exceptions.remove(callback_exception)
                    raise callback_exception

            if r == 0:
                break

    def add_object(self, path, interface, vtable, deprectiated=False, hidden=False):
        obj = Object(self, path, interface, vtable, deprectiated, hidden)
        self.objects.append(obj)

    def remove_object(self, obj):
        self.objects.remove(obj)

    def get_fd(self):
        return _sdbus_h.sd_bus_get_fd(self.bus)
