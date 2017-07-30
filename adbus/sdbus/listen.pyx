# == Copyright: 2017, CCX Technologies

cdef void _listen_message_handler(Listen listen, Message message):
    cdef list args

    args = message.read(listen.signature)

    try:
        listen.callback(*args)
    except Exception as e:
        listen.loop.call_exception_handler({'message': str(e), 'exception': e})

cdef int listen_message_handler(sdbus_h.sd_bus_message *m,
        void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *listen_ptr = <PyObject*>userdata
    cdef Listen listen = <Listen>listen_ptr
    cdef Message message = Message()

    message.import_sd_bus_message(m)
    listen.loop.run_in_executor(None, _listen_message_handler, listen, message)
    return 1

cdef class Listen:
    cdef bytes match
    cdef object callback
    cdef bytes signature

    cdef sdbus_h.sd_bus_slot *_slot
    cdef object loop

    def __cinit__(self, Service service, address, path, interface, member,
            callback, args=(), signature=''):

        match = []
        match.append(f"sender='{address}'")
        match.append("type='signal'")
        match.append(f"interface='{interface}'")
        match.append(f"member='{member}'")
        match.append(f"path='{path}'")
        match += [f"arg{i}='{a}'" for i,a in enumerate(args)]

        self.match = (','.join(match)).encode()
        self.callback = callback
        self.signature = signature.encode()
        self.loop = service.loop

        ret = sdbus_h.sd_bus_add_match(service.bus, &self._slot, self.match,
            listen_message_handler, <void *>self)
        if ret < 0:
            raise SdbusError(f"Failed to add match: {errorcode[-ret]}", -ret)

    def __dealloc__(self):
        self._slot = sdbus_h.sd_bus_slot_unref(self._slot)
