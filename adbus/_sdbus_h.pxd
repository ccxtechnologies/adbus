# == Based on libsystemd's v232 dbus library
# == Copyright: 2017, Charles Eidsness

from libc cimport stdint

cdef extern from "systemd/sd-bus.h":

    # -- Callbacks --

    ctypedef int (*sd_bus_message_handler_t)(sd_bus_message *m, 
            void *userdata, sd_bus_error *ret_error)

    ctypedef int (*sd_bus_property_get_t) (sd_bus *bus, const char *path, 
            const char *interface, const char *property, 
            sd_bus_message *reply, void *userdata, sd_bus_error *ret_error)

    ctypedef int (*sd_bus_property_set_t) (sd_bus *bus, const char *path, 
            const char *interface, const char *property, 
            sd_bus_message *value, void *userdata, sd_bus_error *ret_error)
    
    
ctypedef struct sd_bus_vtable_start:
    size_t element_size

ctypedef struct sd_bus_vtable_method:
    const char *member
    const char *signature
    const char *result
    sd_bus_message_handler_t handler
    size_t offset

ctypedef struct sd_bus_vtable_signal:
    const char *member
    const char *signature

ctypedef struct sd_bus_vtable_property:
    const char *member
    const char *signature
    sd_bus_property_get_t get
    sd_bus_property_set_t set
    size_t offset

cdef extern from "systemd/sd-bus-vtable.h":

    # -- Constants --

    cdef enum:
        _SD_BUS_VTABLE_START             = 60 # ascii '<'
        _SD_BUS_VTABLE_END               = 62 # ascii '>'
        _SD_BUS_VTABLE_METHOD            = 77 # ascii 'M'
        _SD_BUS_VTABLE_SIGNAL            = 83 # ascii 'S'
        _SD_BUS_VTABLE_PROPERTY          = 80 # ascii 'P'
        _SD_BUS_VTABLE_WRITABLE_PROPERTY = 87 # ascii 'W'

    cdef enum:
        SD_BUS_VTABLE_DEPRECATED                   = 1 << 0
        SD_BUS_VTABLE_HIDDEN                       = 1 << 1
        SD_BUS_VTABLE_UNPRIVILEGED                 = 1 << 2
        SD_BUS_VTABLE_METHOD_NO_REPLY              = 1 << 3
        SD_BUS_VTABLE_PROPERTY_CONST               = 1 << 4
        SD_BUS_VTABLE_PROPERTY_EMITS_CHANGE        = 1 << 5
        SD_BUS_VTABLE_PROPERTY_EMITS_INVALIDATION  = 1 << 6
        SD_BUS_VTABLE_PROPERTY_EXPLICIT            = 1 << 7
    
    # -- Structs --

    ctypedef union sd_bus_vtable_data:
        sd_bus_vtable_start start
        sd_bus_vtable_method method
        sd_bus_vtable_signal signal
        sd_bus_vtable_property property
    
    ctypedef struct sd_bus_vtable:
        stdint.uint64_t flags
        sd_bus_vtable_data x
    
cdef extern from "systemd/sd-bus.h":

    # -- Constants --
    
    cdef enum:
        SD_BUS_NAME_REPLACE_EXISTING  = 1 << 0
        SD_BUS_NAME_ALLOW_REPLACEMENT = 1 << 1
        SD_BUS_NAME_QUEUE             = 1 << 2
    
    # -- Structs --
    
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
    
    # -- Functions --

    int sd_bus_open_user(sd_bus **ret)
    int sd_bus_open_system(sd_bus **ret)
    int sd_bus_request_name(sd_bus *bus, const char *name, stdint.uint64_t flags)
    sd_bus *sd_bus_unref(sd_bus *bus)

    int sd_bus_add_object_vtable(sd_bus *bus, sd_bus_slot **slot, 
            const char *path, const char *interface, 
            const sd_bus_vtable *vtable, void *userdata)
    sd_bus_slot* sd_bus_slot_unref(sd_bus_slot *slot)

    int sd_bus_process(sd_bus *bus, sd_bus_message **r)
    int sd_bus_wait(sd_bus *bus, stdint.uint64_t timeout_usec)
