# == Copyright: 2017, Charles Eidsness

cdef class BusError(Exception):
    """D-Bus Bus Error (i.e. failed to connect)"""
    pass

include "_sdbus/service.pyx"
include "_sdbus/object.pyx"

