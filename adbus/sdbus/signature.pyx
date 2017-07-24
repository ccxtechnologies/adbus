# Copyright: 2017, CCX Technologies

cdef bytes signature_variant = int(sdbus_h.SD_BUS_TYPE_VARIANT).to_bytes(1, 'big')
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

def variant_signature():
    return signature_variant.decode()

def py_signature(obj):
    """Calculates a D-Bus Signature from a Python object or type.

    Args:
        obj (obj or type): Python object or type,
            supports bool, int, str, float, bytes, and from the
            typing library, List, Dict, and Tuple

    Returns:
        A string representing the D-Bus Signature.
    """
    return _object_signature(obj).decode()
