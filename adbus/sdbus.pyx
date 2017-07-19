# Copyright: 2017, CCX Technologies

import re
cimport sdbus_h

from typing import GenericMeta
from typing import TupleMeta
from asyncio import get_event_loop
from concurrent.futures import ThreadPoolExecutor
from errno import errorcode
from libc cimport stdint
from libc cimport stdio
from cpython.mem cimport PyMem_Malloc
from cpython.mem cimport PyMem_Free
from libc.string cimport memcpy
from libc.string cimport strncpy
from libc.string cimport strlen
from cpython.ref cimport PyObject
from cpython cimport bool

# -----------

cdef class BusError(Exception):
    """D-Bus Bus Error (i.e. failed to connect)"""
    pass

cdef class SdbusError(Exception):
    """SD-Bus Library Configuration Error"""

    def __init__(self, message, errno=1):
        Exception.__init__(self, message)
        self.errno = errno

# -----------

include "sdbus/snake.pyx"
include "sdbus/signature.pyx"
include "sdbus/message.pyx"
include "sdbus/error.pyx"
include "sdbus/service.pyx"
include "sdbus/object.pyx"
include "sdbus/manager.pyx"
include "sdbus/method.pyx"
include "sdbus/property.pyx"
include "sdbus/signal.pyx"
