# == Copyright: 2017, Charles Eidsness

cimport csdbus

cdef class Service:
    cdef csdbus.sd_bus *_bus

    def __cinit__(self, name):
        if csdbus.sd_bus_open_user(&self._bus) < 0:
            raise RuntimeError("Failed to connect to Bus")

        #TODO: Make sure it's a valid name
        if csdbus.sd_bus_request_name(self._bus, name.encode('utf-8'), 0) < 0:
            raise RuntimeError("Failed to acquire name {}".format(name))

    def __init__(self, name):
        pass

    def __dealloc__(self):
        self._bus = csdbus.sd_bus_unref(self._bus)

