
# == Based on libsystemd's v232 dbus library
# == Copyright: 2017, Charles Eidsness

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


