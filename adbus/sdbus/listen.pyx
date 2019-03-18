# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef int listen_message_handler(sdbus_h.sd_bus_message *m,
        void *userdata, sdbus_h.sd_bus_error *err):
    cdef PyObject *listen_ptr = <PyObject*>userdata
    cdef Listen listen = <Listen>listen_ptr
    cdef Message message = Message()

    message.import_sd_bus_message(m)
    args = message.read(listen.signature)
    if listen.seperate_arguments:
        ensure_future(listen.coroutine(*args), loop=listen.loop)
    else:
        ensure_future(listen.coroutine(args), loop=listen.loop)
    return 1

cdef class Listen:
    cdef bytes match
    cdef object coroutine
    cdef bytes signature
    cdef bool seperate_arguments

    cdef sdbus_h.sd_bus_slot *_slot
    cdef object loop

    def __cinit__(self, Service service, address, path, interface, member,
            coroutine, args=(), signature=b'ANY', seperate_arguments=True):

        match = []
        match.append(f"sender='{address}'")
        match.append("type='signal'")
        match.append(f"interface='{interface}'")
        match.append(f"member='{member}'")
        match.append(f"path='{path}'")
        match += [f"arg{i}='{a}'" for i,a in enumerate(args)]

        self.match = (','.join(match)).encode()
        self.coroutine = coroutine
        self.signature = signature
        self.loop = service.loop
        self.seperate_arguments = seperate_arguments

        ret = sdbus_h.sd_bus_add_match(service.bus, &self._slot, self.match,
            listen_message_handler, <void *>self)
        if ret < 0:
            raise SdbusError(f"Failed to add match: {errorcode[-ret]}", -ret)

    def __dealloc__(self):
        self._slot = sdbus_h.sd_bus_slot_unref(self._slot)
