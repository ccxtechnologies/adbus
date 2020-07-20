# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef void _method_message_handler(Method method, Message message):
    cdef Error error
    cdef list args
    cdef object value

    args = message.read(method.arg_signature)

    try:
        if method.instance:
            value = method.callback(<object>(method.instance), *args)
        else:
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
    method.loop.run_in_executor(method.executor, _method_message_handler, method, message)
    return 1

cdef class Method:

    cdef stdint.uint8_t type
    cdef stdint.uint64_t flags
    cdef sdbus_h.sd_bus_vtable_method x
    cdef void *userdata
    cdef object callback
    cdef object py_instance
    cdef PyObject *instance
    cdef bytes name
    cdef bytes arg_signature
    cdef bytes return_signature
    cdef bool connected
    cdef object loop
    cdef object executor

    def __cinit__(self, name, callback, arg_signature='', return_signature='',
            deprecated=False, hidden=False, unprivileged=False, no_reply=False, instance=None, executor=None):

        self.name = name.encode()
        self.arg_signature = arg_signature[1:].encode() if instance is not None else arg_signature.encode()
        self.return_signature = return_signature.encode()
        self.callback = callback
        self.py_instance = instance
        self.connected = False
        self.executor = executor

        self.type = sdbus_h._SD_BUS_VTABLE_METHOD

        self.flags = 0
        if no_reply:
            self.flags |= sdbus_h.SD_BUS_VTABLE_METHOD_NO_REPLY

        if deprecated:
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
        if self.connected:
            raise SdbusError("Method already associated")
        self.connected = True

        # this decrements the counter of py_instance so if it
        # refers to the base object the object won't be held in
        # memory indefinitely (self-referenced)
        self.instance = <PyObject *>self.py_instance
        self.py_instance = None

        self.loop = object.loop
