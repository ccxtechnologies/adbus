# Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef bytes signature_variant = int(sdbus_h.SD_BUS_TYPE_VARIANT).to_bytes(1, 'big')
cdef bytes signature_boolean = int(sdbus_h.SD_BUS_TYPE_BOOLEAN).to_bytes(1, 'big')
cdef bytes signature_byte = int(sdbus_h.SD_BUS_TYPE_BYTE).to_bytes(1, 'big')
cdef bytes signature_int = int(sdbus_h.SD_BUS_TYPE_INT32).to_bytes(1, 'big')
cdef bytes signature_float = int(sdbus_h.SD_BUS_TYPE_DOUBLE).to_bytes(1, 'big')
cdef bytes signature_string = int(sdbus_h.SD_BUS_TYPE_STRING).to_bytes(1, 'big')
cdef bytes signature_array = int(sdbus_h.SD_BUS_TYPE_ARRAY).to_bytes(1, 'big')
cdef bytes signature_dict_begin = int(sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN).to_bytes(1, 'big')
cdef bytes signature_dict_end = int(sdbus_h.SD_BUS_TYPE_DICT_ENTRY_END).to_bytes(1, 'big')
cdef bytes signature_struct_begin = int(sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN).to_bytes(1, 'big')
cdef bytes signature_struct_end = int(sdbus_h.SD_BUS_TYPE_STRUCT_END).to_bytes(1, 'big')
cdef bytes signature_invalid = b'E'

cdef bytes _object_signature_basic(object obj):
    if (obj == bool) or isinstance(obj, bool):
        return signature_boolean
    elif (obj == int) or isinstance(obj, int):
        return signature_int
    elif (obj == float) or isinstance(obj, float):
        return signature_float
    elif (obj == str) or isinstance(obj, str):
        return signature_string
    elif (obj == bytes) or isinstance(obj, bytes):
        return signature_string
    elif obj == Any:
        return signature_variant
    return signature_invalid

cdef bytes _object_signature(object obj):
    cdef bytes signature = b''

    if obj is None:
        return signature

    if hasattr(obj, 'dbus_signature'):
        return obj.dbus_signature.encode('utf-8')

    elif isinstance(obj, dict):
        signature += signature_array
        signature += signature_dict_begin
        signature += _object_signature_basic(next(iter(obj.keys())))
        signature += _object_signature(next(iter(obj.values())))
        signature += signature_dict_end

    elif isinstance(obj, list):
        try:
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
        except:
            signature += signature_string

    elif isinstance(obj, tuple):
        signature += signature_struct_begin
        for v in obj:
            signature += _object_signature(v)
        signature += signature_struct_end

    elif isinstance(obj, _GenericAlias) and (obj.__origin__ == dict):
        signature += signature_array
        signature += signature_dict_begin
        signature += _object_signature_basic(obj.__args__[0])
        signature += _object_signature(obj.__args__[1])
        signature += signature_dict_end

    elif isinstance(obj, _GenericAlias) and (obj.__origin__ == list):
        signature += signature_array
        signature += _object_signature(obj.__args__[0])

    elif isinstance(obj, _GenericAlias) and (obj.__origin__ == tuple):
        signature += signature_struct_begin
        for v in obj.__args__:
            signature += _object_signature(v)
        signature += signature_struct_end

    else:
        signature += _object_signature_basic(obj)

    return signature

def variant_signature():
    return signature_variant.decode()

cdef bytes _dbus_signature(obj):
    cdef bytes signature = _object_signature(obj)

    if signature_invalid in signature:
        raise TypeError(f"No D-Bus type equivalent for {obj}")

    return signature

def dbus_signature(obj):
    """Calculates a D-Bus Signature from a Python object or type.

    Args:
        obj (object or type): Python object or type,
            If the object has a dbus_signature attribute it will
            be used, otherwise the object or type will be parsed
            to calculate the D-Bus Signature.
            Supports bool, int, str, float, bytes, and from the
            typing library, List, Dict, and Tuple.

    Returns:
        A string representing the D-Bus Signature.

    Raises:
        TypeError: If no D-Bus Equivalent for objects type.
    """
    signature = _dbus_signature(obj)

    try:
        return signature.decode()
    except UnicodeDecodeError:
        # There is a memory management bug that rarely results in a Unicode Decode
        # error, this was added to get a little more info when it happens, but it
        # hasn't happened since this was added...
        import syslog
        syslog.syslog(f"==> {obj} === {signature}")
        raise

cdef object _object_cast_basic(bytes signature, object obj):
    if signature[0] == sdbus_h.SD_BUS_TYPE_BOOLEAN :
        return bool(obj)
    elif signature[0] == sdbus_h.SD_BUS_TYPE_INT32:
        return int(obj)
    elif signature[0] == sdbus_h.SD_BUS_TYPE_DOUBLE:
        return float(obj)
    elif signature[0] == sdbus_h.SD_BUS_TYPE_STRING:
        if type(obj) == bytes:
            return obj.decode('utf-8', errors='ignore')
        return str(obj)
    return obj

cdef object _object_cast(bytes signature, object obj):

    if hasattr(obj, 'dbus_value'):
        obj = obj.dbus_value

    if signature[0] == sdbus_h.SD_BUS_TYPE_ARRAY:
        if signature[1] == sdbus_h.SD_BUS_TYPE_DICT_ENTRY_BEGIN:
            return {_object_cast_basic(signature[2:], k): _object_cast(signature[3:], v)
                    for k,v in obj.items()}
        else:
            return [_object_cast(signature[1:], v) for v in obj]
    elif signature[0] == sdbus_h.SD_BUS_TYPE_STRUCT_BEGIN:
        return tuple([_object_cast(signature[2:], v) for v in obj])

    else:
        return _object_cast_basic(signature, obj)

def dbus_cast(signature, obj):
    """Casts an object into the type defined in a D-Bus signature.

    Args:
        signature (str): D-Bus type signature
        obj (object or type): Python object or type

    Returns:
        A new type, cast from the D-Bus Signature.

    """
    return _object_cast(signature.encode(), obj)
