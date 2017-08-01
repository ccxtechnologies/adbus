# Copyright: 2017, CCX Technologies
"""Interface to the systemd sd-bus library, not expected to be directly
    called by external applications."""

import re
cimport sdbus_h

from typing import GenericMeta
from typing import TupleMeta
from typing import Any
from asyncio import get_event_loop
from asyncio import Event
from asyncio import wait_for
from asyncio import ensure_future
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
from .exceptions import BusError

cdef class SdbusError(Exception):
    """SD-Bus Library Configuration Error"""

    def __init__(self, message, errno=1):
        Exception.__init__(self, message)
        self.errno = errno

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
include "sdbus/call.pyx"
include "sdbus/listen.pyx"
