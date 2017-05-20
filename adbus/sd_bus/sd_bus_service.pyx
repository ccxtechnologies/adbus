# == Copyright: 2017, Charles Eidsness

cimport sd_bus_h

cdef class SdBusServiceBusError(Exception):
    """D-Bus Bus Error (i.e. failed to connect)"""
    pass

cdef int message_handler(sd_bus_h.sd_bus_message *m, 
        void *f, sd_bus_h.sd_bus_error *e):
    (<object>f)()
    return 0

cdef class SdBusService:
    cdef sd_bus_h.sd_bus *_bus
    cdef sd_bus_h.sd_bus_slot *_slot

    def __cinit__(self, name, system=False):
        if system:
            if sd_bus_h.sd_bus_open_system(&self._bus) < 0:
                raise SdBusServiceBusError("Failed to connect to Bus")

        else:
            if sd_bus_h.sd_bus_open_user(&self._bus) < 0:
                raise SdBusServiceBusError("Failed to connect to Bus")

        if sd_bus_h.sd_bus_request_name(self._bus, name.encode('utf-8'), 0) < 0:
            raise SdBusServiceBusError(f"Failed to acquire name {name}")

    def __dealloc__(self):
        self._bus = sd_bus_h.sd_bus_unref(self._bus)

    def add_object(self, path, callback):
        if sd_bus_h.sd_bus_add_object(self._bus, &self._slot, 
                path.encode('utf-8'), message_handler, <void*>callback) < 0:
            raise SdBusServiceBusError(f"Failed to add object at {path}")

    def process(self):
        while True:
            r = sd_bus_h.sd_bus_process(self._bus, NULL)
            if r < 0:
                raise SdBusServiceBusError("Failed to process bus")
            if r > 0:
                continue

            if sd_bus_h.sd_bus_wait(self._bus, -1) < 0:
                raise SdBusServiceBusError("Failed to wait for bus")

