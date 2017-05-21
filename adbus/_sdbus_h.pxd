# == Based on libsystemd's v232 dbus library
# == Copyright: 2017, Charles Eidsness

from libc cimport stdint

cdef extern from "systemd/sd-bus.h":

    ctypedef struct sd_bus:
        pass
    
    ctypedef struct sd_bus_message:
        pass
    
    ctypedef struct sd_bus_slot:
        pass

    ctypedef struct sd_bus_error:
        const char *name
        const char *message
        int _need_free

    ctypedef struct sd_bus_error_map:
        const char* name
        int code
        
    cdef enum:
        SD_BUS_NAME_REPLACE_EXISTING  = 1 << 0
        SD_BUS_NAME_ALLOW_REPLACEMENT = 1 << 1
        SD_BUS_NAME_QUEUE             = 1 << 2

    ctypedef int (*sd_bus_message_handler_t)(sd_bus_message *m, 
            void *userdata, sd_bus_error *ret_error)

    int sd_bus_open_user(sd_bus **ret)
    int sd_bus_open_system(sd_bus **ret)
    int sd_bus_request_name(sd_bus *bus, const char *name, stdint.uint64_t flags)
    sd_bus *sd_bus_unref(sd_bus *bus)

    int sd_bus_add_object(sd_bus *bus, sd_bus_slot **slot, 
            const char *path, sd_bus_message_handler_t callback, void *userdata);

    int sd_bus_process(sd_bus *bus, sd_bus_message **r)
    int sd_bus_wait(sd_bus *bus, stdint.uint64_t timeout_usec)
