# == Copyright: 2017, Charles Eidsness

cdef int method_message_handler(sdbus_h.sd_bus_message *m,
        void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *method_ptr = (((<PyObject**>userdata)[0]))
    cdef Method method = <Method>method_ptr
    cdef Message message = Message()
    cdef Error error
    cdef list args
    cdef object value

    message.import_sd_bus_message(m)
    args = message.read(method.arg_signature)

    try:
        value = method.callback(*args)
    except Exception as e:
        error = Error()
        error.import_sd_bus_error(err)
        method.exceptions.append(e)
        return error.from_exception(e)

    message.new_method_return(m)
    message.append(method.return_signature, value)

    try:
        message.send()
    except SdbusError as e:
        return -e.errno
    else:
        return 1

cdef class Method:
    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_method x
    cdef void *userdata
    cdef object callback
    cdef bytes name
    cdef bytes arg_signature
    cdef bytes return_signature
    cdef list exceptions
    cdef Object object

    def __cinit__(self, name, callback, arg_signature='', return_signature='',
            deprectiated=False, hidden=False, unprivledged=False):

        self.name = name.encode()
        self.arg_signature = arg_signature.encode()
        self.return_signature = return_signature.encode()
        self.callback = callback
        self.exceptions = []
        self.object = None

        self.type = sdbus_h._SD_BUS_VTABLE_METHOD

        self.flags = 0
        if not return_signature:
            self.flags |= sdbus_h.SD_BUS_VTABLE_METHOD_NO_REPLY

        if deprectiated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        if unprivledged:
            self.flags |= sdbus_h.SD_BUS_VTABLE_UNPRIVILEGED

        self.x.member = self.name
        self.x.handler = method_message_handler
        self.x.signature = self.arg_signature
        self.x.result = self.return_signature

        self.userdata = <void *>self

    cdef populate_vtable(self, sdbus_h.sd_bus_vtable *vtable):
        vtable.type = self.type
        vtable.flags = self.flags
        memcpy(&vtable.x, &self.x, sizeof(self.x))

    cdef set_object(self, object):
        if self.object:
            raise SdbusError("Method already associated")
        self.object = object
