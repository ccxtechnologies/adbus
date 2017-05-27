# == Copyright: 2017, Charles Eidsness

cimport _sdbus_h

from libc cimport stdint
from libc cimport stdio
from cpython.mem cimport PyMem_Malloc
from cpython.mem cimport PyMem_Free
from libc.string cimport memcpy

cdef class BusError(Exception):
    """D-Bus Bus Error (i.e. failed to connect)"""
    pass

cdef class SdbusError(Exception):
    """SD-Bus Library Configuration Error"""
    pass

include "_sdbus/service.pyx"
include "_sdbus/object.pyx"
include "_sdbus/method.pyx"

