# == Copyright: 2017, Charles Eidsness

cdef class Message:
    
    @staticmethod
    cdef list args(_sdbus_h.sd_bus_message *message):
        cdef const char * types
        stack = []

        types = _sdbus_h.sd_bus_message_get_signature(message, 0)
        
        if types == NULL:
            raise SdbusError("NULL Message")

        print(f"Data Types {types}")

        return [b'tester']

