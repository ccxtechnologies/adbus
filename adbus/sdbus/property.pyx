# == Copyright: 2017, CCX Technologies

cdef int property_get_handler(sdbus_h.sd_bus *bus,
            const char *path, const char *interface, const char *propname,
            sdbus_h.sd_bus_message *m, void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *property_ptr = (((<PyObject**>userdata)[0]))
    cdef Property property = <Method>property_ptr
    cdef Message message = Message()
    cdef Error error
    cdef object value

    message.import_sd_bus_message(m)

    try:
        value = getattr(property.py_object, property.attr_name)
        message.append(property.signature, value)
    except Exception as e:
        error = Error()
        error.import_sd_bus_error(err)
        property.exceptions.append(e)
        return error.from_exception(e)

    return 1

cdef int property_set_handler(sdbus_h.sd_bus *bus,
            const char *path, const char *interface, const char *propname,
            sdbus_h.sd_bus_message *m, void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *property_ptr = (((<PyObject**>userdata)[0]))
    cdef Property property = <Method>property_ptr
    cdef Message message = Message()
    cdef Error error
    cdef list values

    message.import_sd_bus_message(m)
    values = message.read(property.signature)

    try:
        setattr(property.py_object, property.attr_name, values[0])
    except Exception as e:
        error = Error()
        error.import_sd_bus_error(err)
        property.exceptions.append(e)
        return error.from_exception(e)

    return 1

cdef class Property:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_property x
    cdef void *userdata
    cdef object py_object
    cdef str attr_name
    cdef bytes name
    cdef bytes signature
    cdef list exceptions
    cdef Object object

    def __cinit__(self, name, py_object, attr_name, signature='', read_only=False,
            depreciated=False, hidden=False, unprivledged=False,
            emits_constant=False, emits_change=False, emits_invalidation=False):

        self.name = name.encode()
        self.py_object = py_object
        self.attr_name = attr_name
        self.signature = signature.encode()
        self.exceptions = []
        self.object = None

        if read_only:
            self.type = sdbus_h._SD_BUS_VTABLE_PROPERTY
        else:
            self.type = sdbus_h._SD_BUS_VTABLE_WRITABLE_PROPERTY

        self.flags = 0
        if depreciated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        if unprivledged:
            self.flags |= sdbus_h.SD_BUS_VTABLE_UNPRIVILEGED

        if emits_constant:
            self.flags |= sdbus_h.SD_BUS_VTABLE_PROPERTY_CONST

        if emits_change:
            self.flags |= sdbus_h.SD_BUS_VTABLE_PROPERTY_EMITS_CHANGE

        if emits_invalidation:
            self.flags |= sdbus_h.SD_BUS_VTABLE_PROPERTY_EMITS_INVALIDATION

        self.x.member = self.name
        self.x.get = property_get_handler
        if not read_only:
            self.x.set = property_set_handler
        else:
            self.x.set = NULL
        self.x.signature = self.signature

        self.userdata = <void *>self

    def get_name(self):
        return self.name

    cdef populate_vtable(self, sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))

    cdef set_object(self, object):
        if self.object:
            raise SdbusError("Property already associated")
        self.object = object

    def emit_changed(self):
        if not self.object:
            raise SdbusError("Signal not associated")
        return self.object.emit_properties_changed([self.name.decode()])

