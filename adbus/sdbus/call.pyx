# == Copyright: 2017, CCX Technologies

cdef int async_polkit_callback(sd_bus_message *reply,
        void *userdata, sd_bus_error *error):

    # process response, refer to async_polkit_callback in
    # systemd-232/src/shared/bus-util.c

    # wake up sleeping call

async def call(service, address, path, interface, method, args=None,
        timeout_ms=30000):

    # ---- add message stuff to existing Message Class
    # 1. create message (need to store message)
    int sd_bus_message_new_method_call(sd_bus *bus, sd_bus_message **m,
            const char *destination, const char *path, const char *interface,
            const char *member);

    # 2. add arguments to message

    # 3. send message
    int sd_bus_call_async(sd_bus *bus, sd_bus_slot **slot, sd_bus_message *m,
            sd_bus_message_handler_t callback, void *userdata, uint64_t usec);

    # 4. await for the response (using a queue)?

    # 5. return response

    pass

