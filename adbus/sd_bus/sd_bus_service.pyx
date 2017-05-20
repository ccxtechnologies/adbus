# == Copyright: 2017, Charles Eidsness

cimport sd_bus_h

cdef class SdBusServiceBusError(Exception):
    """D-Bus Bus Error (i.e. failed to connect)"""
    pass

cdef class SdBusService:
    cdef sd_bus_h.sd_bus *_bus

    def __cinit__(self, name):
        if sd_bus_h.sd_bus_open_user(&self._bus) < 0:
            raise SdBusServiceBusError("Failed to connect to Bus")

        #TODO: Make sure it's a valid name
        if sd_bus_h.sd_bus_request_name(self._bus, name.encode('utf-8'), 0) < 0:
            raise SdBusServiceBusError(f"Failed to acquire name {name}")

    def __init__(self, name):
        pass

    def __dealloc__(self):
        self._bus = sd_bus_h.sd_bus_unref(self._bus)

