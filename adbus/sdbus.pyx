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

def snake_to_camel(snake):
    """Converts a snake_case string to CamelCase.

    Args:
        snake (str): Underscore separated string

    Returns:
        A string in CamelCase.
    """
    return "".join(x[:1].upper() + x[1:] for x in snake.split("_"))

first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')
def camel_to_snake(camel):
    """Converts CamelCase separated string to snake_case.

    Args:
        camel (str): CamelCase separated string

    Returns:
        A string in snake_case.
    """
    s1 = first_cap_re.sub(r'\1_\2', camel)
    return all_cap_re.sub(r'\1_\2', s1).lower()

# -----------

cdef bytes signature_byte = int(sdbus_h.SD_BUS_TYPE_BYTE).to_bytes(1, 'big')
cdef bytes signature_int = int(sdbus_h.SD_BUS_TYPE_INT32).to_bytes(1, 'big')
cdef bytes signature_float = int(sdbus_h.SD_BUS_TYPE_DOUBLE).to_bytes(1, 'big')
cdef bytes signature_string = int(sdbus_h.SD_BUS_TYPE_STRING).to_bytes(1, 'big')
cdef bytes signature_array = int(sdbus_h.SD_BUS_TYPE_ARRAY).to_bytes(1, 'big')
cdef bytes signature_dict_begin = int(sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN).to_bytes(1, 'big')
cdef bytes signature_dict_end = int(sdbus_h.SD_BUS_TYPE_DICT_ENTRY_END).to_bytes(1, 'big')
cdef bytes signature_struct_begin = int(sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN).to_bytes(1, 'big')
cdef bytes signature_struct_end = int(sdbus_h.SD_BUS_TYPE_STRUCT_END).to_bytes(1, 'big')

cdef bytes _object_signature_basic(object obj):
    if (obj == bool) or isinstance(obj, bool):
        return signature_byte
    elif (obj == int) or isinstance(obj, int):
        return signature_int
    elif (obj == float) or isinstance(obj, float):
        return signature_float
    elif (obj == str) or isinstance(obj, str):
        return signature_string
    elif (obj == bytes) or isinstance(obj, bytes):
        return signature_string
    return b''

cdef const char* _object_signature(object obj):
    cdef bytes signature = b''

    if hasattr(obj, 'dbus_signature'):
        signature += obj.dbus_signature.encode('utf-8')
    else:
        signature += _object_signature_basic(obj)

    if signature:
        pass

    elif isinstance(obj, dict):
        signature += signature_array
        signature += signature_dict_begin
        signature += _object_signature_basic(next(iter(obj.keys())))
        signature += _object_signature_basic(next(iter(obj.values())))
        signature += signature_dict_end

    elif isinstance(obj, list):
        if all(isinstance(v, type(obj[0])) for v in obj):
            # if all the same type it's an array
            signature += signature_array
            signature += _object_signature(obj[0])
        else:
            # otherwise it's a struct
            signature += signature_struct_begin
            for v in obj:
                signature += _object_signature(v)
            signature += signature_struct_end

    elif isinstance(obj, GenericMeta) and (obj.__extra__ == dict):
        signature += signature_array
        signature += signature_dict_begin
        signature += _object_signature_basic(obj.__args__[0])
        signature += _object_signature_basic(obj.__args__[1])
        signature += signature_dict_end

    elif isinstance(obj, GenericMeta) and (obj.__extra__ == list):
        signature += signature_array
        signature += _object_signature(obj.__args__[0])

    elif isinstance(obj, TupleMeta) and (obj.__extra__ == tuple):
        signature += signature_struct_begin
        for v in obj.__args__:
            signature += _object_signature(v)
        signature += signature_struct_end

    return signature

def object_signature(obj):
    """Calculates a D-Bus Signature from a Python object or type.

    Args:
        obj (obj or type): Python object or type.
            supports bool, int, str, float, bytes, and from the
            typing library, List, Dict, and Tuple

    Returns:
        A string representing the D-Bus Signature.
    """
    return _object_signature(obj).decode()

include "sdbus/message.pyx"
include "sdbus/error.pyx"
include "sdbus/service.pyx"
include "sdbus/object.pyx"
include "sdbus/manager.pyx"
include "sdbus/method.pyx"
include "sdbus/property.pyx"
include "sdbus/signal.pyx"
