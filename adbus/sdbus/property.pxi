# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef int property_get_handler(sdbus_h.sd_bus *bus,
            const char *path, const char *interface, const char *propname,
            sdbus_h.sd_bus_message *m, void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *property_ptr = (((<PyObject**>userdata)[0]))
    cdef Property property = <Method>property_ptr
    cdef Message message = Message()
    cdef object value
    cdef bytes err_name
    cdef bytes err_message

    message.import_sd_bus_message(m)

    try:
        value = getattr(<object>(property.instance), property.attr_name)
        message.append(property.signature, value)
    except Exception as e:
        property.loop.call_exception_handler({'message': f"{e} for {property.attr_name} <{property.signature}>", 'exception': e})

		#NOTE: sd_bus uses the System.Error prefix for general purpose errors
        err_name = b"System.Error." + \
            e.__class__.__name__.encode('utf-8')
        err_message = f"{e} for {property.attr_name} <{property.signature}>".encode('utf-8')
        sdbus_h.sd_bus_error_set(err, err_name, err_message)

        return -1

    return 1

cdef int property_set_handler(sdbus_h.sd_bus *bus,
            const char *path, const char *interface, const char *propname,
            sdbus_h.sd_bus_message *m, void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *property_ptr = (((<PyObject**>userdata)[0]))
    cdef Property property = <Method>property_ptr
    cdef Message message = Message()
    cdef Error error
    cdef list values
    cdef bytes err_name
    cdef bytes err_message

    message.import_sd_bus_message(m)
    values = message.read(property.signature)

    try:
        # If the old value was created with a dbus_value property then
        # need to create a new instance of that object
        old_value = getattr(<object>(property.instance), property.attr_name)
        if hasattr(old_value, 'dbus_value'):
            value = type(old_value)(values[0])
        else:
            value = values[0]

        setattr(<object>(property.instance), property.attr_name, value)
    except Exception as e:
        property.loop.call_exception_handler({'message': f"{e} for {property.attr_name}", 'exception': e})

		#NOTE: sd_bus uses the System.Error prefix for general purpose errors
        err_name = b"System.Error." + \
            e.__class__.__name__.encode('utf-8')
        err_message = f"{e} for {property.attr_name}".encode('utf-8')
        sdbus_h.sd_bus_error_set(err, err_name, err_message)

        return -1

    return 1

cdef class Property:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_property x
    cdef void *userdata
    cdef object py_instance
    cdef PyObject *instance
    cdef str attr_name
    cdef bytes name
    cdef bytes signature
    cdef bool connected
    cdef object loop

    def __cinit__(self, name, py_object, attr_name, signature='', read_only=False,
            deprecated=False, hidden=False, unprivileged=False,
            emits_constant=False, emits_change=False, emits_invalidation=False):

        self.name = name.encode()
        self.py_instance = py_object
        self.attr_name = attr_name
        self.signature = signature.encode()
        self.connected = False

        if read_only:
            self.type = sdbus_h._SD_BUS_VTABLE_PROPERTY
        else:
            self.type = sdbus_h._SD_BUS_VTABLE_WRITABLE_PROPERTY

        self.flags = 0
        if deprecated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        if unprivileged:
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

    cdef populate_vtable(self, sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))

    cdef set_object(self, Object object):
        if self.connected:
            raise SdbusError("Property already associated")
        self.connected = True

        # this decrements the counter of py_instance so if it
        # refers to the base object the object won't be held in
        # memory indefinitely (self-referenced)
        self.instance = <PyObject *>self.py_instance
        self.py_instance = None

        self.loop = object.loop

    def emit_changed(self):
        if not self.object:
            raise SdbusError("Property not associated")
        return self.object.emit_properties_changed([self.name.decode()])
