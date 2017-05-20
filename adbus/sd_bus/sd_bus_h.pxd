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

    int sd_bus_open_user(sd_bus **ret)
    int sd_bus_open_system(sd_bus **ret)
    int sd_bus_request_name(sd_bus *bus, const char *name, stdint.uint64_t flags)
    int sd_bus_release_name(sd_bus *bus, const char *name)
    sd_bus *sd_bus_unref(sd_bus *bus)

