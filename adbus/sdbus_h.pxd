# Copyright: 2017, CCX Technologies
#cython: language_level=3

from libc cimport stdint

cdef extern from "systemd/sd-bus-protocol.h":

    cdef enum:
        _SD_BUS_TYPE_INVALID         =   0 # NUL
        SD_BUS_TYPE_BYTE             = 121 # 'y'
        SD_BUS_TYPE_BOOLEAN          =  98 # 'b'
        SD_BUS_TYPE_INT16            = 110 # 'n'
        SD_BUS_TYPE_UINT16           = 113 # 'q'
        SD_BUS_TYPE_INT32            = 105 # 'i'
        SD_BUS_TYPE_UINT32           = 117 # 'u'
        SD_BUS_TYPE_INT64            = 120 # 'x'
        SD_BUS_TYPE_UINT64           = 116 # 't'
        SD_BUS_TYPE_DOUBLE           = 100 # 'd'
        SD_BUS_TYPE_STRING           = 115 # 's'
        SD_BUS_TYPE_OBJECT_PATH      = 111 # 'o'
        SD_BUS_TYPE_SIGNATURE        = 103 # 'g'
        SD_BUS_TYPE_UNIX_FD          = 104 # 'h'
        SD_BUS_TYPE_ARRAY            =  97 # 'a'
        SD_BUS_TYPE_VARIANT          = 118 # 'v'
        SD_BUS_TYPE_STRUCT           = 114 # 'r'
        SD_BUS_TYPE_STRUCT_BEGIN     =  40 # '('
        SD_BUS_TYPE_STRUCT_END       =  41 # ')'
        SD_BUS_TYPE_DICT_ENTRY       = 101 # 'e'
        SD_BUS_TYPE_DICT_ENTRY_BEGIN = 123 # '{'
        SD_BUS_TYPE_DICT_ENTRY_END   = 124 # '}'

cdef extern from "systemd/sd-bus.h":

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

ctypedef union sd_bus_vtable_data:
    sd_bus_vtable_start start
    sd_bus_vtable_method method
    sd_bus_vtable_signal signal
    sd_bus_vtable_property property

cdef extern from "systemd/sd-bus-vtable.h":

    cdef enum:
        _SD_BUS_VTABLE_START             = 60 # ascii '<'
        _SD_BUS_VTABLE_END               = 62 # ascii '>'
        _SD_BUS_VTABLE_METHOD            = 77 # ascii 'M'
        _SD_BUS_VTABLE_SIGNAL            = 83 # ascii 'S'
        _SD_BUS_VTABLE_PROPERTY          = 80 # ascii 'P'
        _SD_BUS_VTABLE_WRITABLE_PROPERTY = 87 # ascii 'W'

    cdef enum:
        SD_BUS_VTABLE_DEPRECATED                   = 1ULL << 0
        SD_BUS_VTABLE_HIDDEN                       = 1ULL << 1
        SD_BUS_VTABLE_UNPRIVILEGED                 = 1ULL << 2
        SD_BUS_VTABLE_METHOD_NO_REPLY              = 1ULL << 3
        SD_BUS_VTABLE_PROPERTY_CONST               = 1ULL << 4
        SD_BUS_VTABLE_PROPERTY_EMITS_CHANGE        = 1ULL << 5
        SD_BUS_VTABLE_PROPERTY_EMITS_INVALIDATION  = 1ULL << 6
        SD_BUS_VTABLE_PROPERTY_EXPLICIT            = 1ULL << 7

    ctypedef struct sd_bus_vtable:
        stdint.uint8_t type
        stdint.uint64_t flags
        sd_bus_vtable_data x

cdef extern from "systemd/sd-bus.h":

    cdef enum:
        SD_BUS_NAME_REPLACE_EXISTING  = 1 << 0
        SD_BUS_NAME_ALLOW_REPLACEMENT = 1 << 1
        SD_BUS_NAME_QUEUE             = 1 << 2

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

    int sd_bus_open_user(sd_bus **ret)
    int sd_bus_open_system(sd_bus **ret)
    int sd_bus_request_name(sd_bus *bus, const char *name, stdint.uint64_t flags)
    int sd_bus_get_unique_name(sd_bus *bus, const char **unique)
    sd_bus *sd_bus_unref(sd_bus *bus)

    int sd_bus_add_object_vtable(sd_bus *bus, sd_bus_slot **slot,
            const char *path, const char *interface,
            const sd_bus_vtable *vtable, void *userdata)
    sd_bus_slot* sd_bus_slot_unref(sd_bus_slot *slot)
    int sd_bus_add_object_manager(sd_bus *bus, sd_bus_slot **slot,
            const char *path)

    int sd_bus_process(sd_bus *bus, sd_bus_message **r)
    int sd_bus_get_fd(sd_bus *bus)

    int sd_bus_message_new_method_return(sd_bus_message *call,
            sd_bus_message **m)
    int sd_bus_message_new_signal(sd_bus *bus, sd_bus_message **m,
            const char *path, const char *interface, const char *member)
    int sd_bus_message_new_method_call(sd_bus *bus, sd_bus_message **m,
            const char *destination, const char *path, const char *interface,
            const char *member)

    const char *sd_bus_message_get_signature(sd_bus_message *m, int complete)
    int sd_bus_message_read_basic(sd_bus_message *m, char type, void *p)

    const sd_bus_error *sd_bus_message_get_error(sd_bus_message *m)
    int sd_bus_message_get_errno(sd_bus_message *m)

    int sd_bus_message_open_container(sd_bus_message *m, char type,
            const char *contents)
    int sd_bus_message_enter_container(sd_bus_message *m, char type,
            const char *contents)
    int sd_bus_message_at_end(sd_bus_message *m, int complete)
    int sd_bus_message_exit_container(sd_bus_message *m)
    int sd_bus_message_close_container(sd_bus_message *m)

    int sd_bus_call_async(sd_bus *bus, sd_bus_slot **slot, sd_bus_message *m,
            sd_bus_message_handler_t callback, void *userdata,
            stdint.uint64_t usec)

    sd_bus_message* sd_bus_message_ref(sd_bus_message *m)
    sd_bus_message* sd_bus_message_unref(sd_bus_message *m)

    int sd_bus_error_set(sd_bus_error *e, const char *name, const char *message)
    int sd_bus_reply_method_error(sd_bus_message *cal, const sd_bus_error *e)
    int sd_bus_error_copy(sd_bus_error *dest, const sd_bus_error *e)

    int sd_bus_message_append_basic(sd_bus_message *m, char type, const void *p)
    int sd_bus_send(sd_bus *bus, sd_bus_message *m, stdint.uint64_t *cookie)

    int sd_bus_emit_properties_changed_strv(sd_bus *bus, const char *path,
            const char *interface, char **names)

    int sd_bus_add_match(sd_bus *bus, sd_bus_slot **slot, const char *match,
            sd_bus_message_handler_t callback, void *userdata)
