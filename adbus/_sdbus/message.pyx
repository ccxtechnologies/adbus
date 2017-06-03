# == Copyright: 2017, Charles Eidsness

cdef list message_read(_sdbus_h.sd_bus_message *m):
    cdef const char * types
    stack = []

    types = _sdbus_h.sd_bus_message_get_signature(m, 0)
    
    if types == NULL:
        raise SdbusError("NULL Message")

    print(f"Data Types {types}")

    return [b'tester']

