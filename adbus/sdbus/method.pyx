# == Copyright: 2017, CCX Technologies

cdef void _method_message_handler(Method method, Message message):
    cdef Error error
    cdef list args
    cdef object value

    args = message.read(method.arg_signature)

    try:
        value = method.callback(*args)
    except Exception as e:
        method.loop.call_exception_handler({'message': str(e), 'exception': e})
        error = Error()
        try:
            error.reply_from_exception(message, e)
        except SdbusError as e:
            method.loop.call_exception_handler({'message': str(e), 'exception': e})
        return

    message.new_method_return()
    message.append(method.return_signature, value)

    try:
        message.send()
    except SdbusError as e:
        method.loop.call_exception_handler({'message': str(e), 'exception': e})

cdef int method_message_handler(sdbus_h.sd_bus_message *m,
        void *userdata, sdbus_h.sd_bus_error *err):

    cdef PyObject *method_ptr = (((<PyObject**>userdata)[0]))
    cdef Method method = <Method>method_ptr
    cdef Message message = Message()

    message.import_sd_bus_message(m)
    method.loop.run_in_executor(None, _method_message_handler, method, message)
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
    cdef Object object
    cdef object loop

    def __cinit__(self, name, callback, arg_signature='', return_signature='',
            depreciated=False, hidden=False, unprivileged=False):

        self.name = name.encode()
        self.arg_signature = arg_signature.encode()
        self.return_signature = return_signature.encode()
        self.callback = callback
        self.object = None

        self.type = sdbus_h._SD_BUS_VTABLE_METHOD

        self.flags = 0
        if not return_signature:
            self.flags |= sdbus_h.SD_BUS_VTABLE_METHOD_NO_REPLY

        if depreciated:
            self.flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self.flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        if unprivileged:
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

    cdef set_object(self, Object object):
        if self.object:
            raise SdbusError("Method already associated")
        self.object = object
        self.loop = object.loop
