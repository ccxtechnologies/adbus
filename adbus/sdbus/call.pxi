# == Copyright: 2017, CCX Technologies
#cython: language_level=3

cdef int call_callback(sdbus_h.sd_bus_message *m, void *userdata,
        sdbus_h.sd_bus_error *err):
    cdef PyObject *call_ptr = <PyObject*>userdata
    cdef Call call = <Call>call_ptr
    cdef Message message = Message()

    call._slot = sdbus_h.sd_bus_slot_unref(call._slot)

    try:
        message.import_sd_bus_message(m)
        response = message.read(call.response_signature)
        if response:
            call.response = response[0]
        else:
            call.response = None
        return 0

    except SdbusError as e:
        call.response = e
        return -e.errno

    finally:
        call.wake()
        Py_DECREF(call)

cdef class Call:
    cdef Message message
    cdef Service service
    cdef sdbus_h.sd_bus_slot *_slot
    cdef public object event
    cdef public object response
    cdef object wait_co
    cdef char *response_signature

    def __cinit__(self, Service service, address, path, interface, method,
            args=None, response_signature=b''):

        self.event = Event(loop=service.loop)
        self.service = service
        self.response = None
        self.message = Message()
        self.message.new_method_call(service, address, path, interface, method)
        self.response_signature = response_signature

        if args:
            for arg in args:
                signature = _dbus_signature(arg)
                self.message.append(signature, arg)

    def send(self, stdint.uint64_t timout_ms):
        cdef int ret
        self.event.clear()

        ret = sdbus_h.sd_bus_call_async(self.service.bus, &self._slot,
                self.message.message, call_callback, <void *>self,
                timout_ms*1000)
        if ret < 0:
            self.event.set()
            raise SdbusError(f"Failed to send call: {errorcode[-ret]}", -ret)

        Py_INCREF(self)

    cdef wake(self):
        self.event.set()
