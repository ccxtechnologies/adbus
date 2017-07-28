# == Copyright: 2017, CCX Technologies

cdef int call_callback(sdbus_h.sd_bus_message *m, void *userdata,
        sdbus_h.sd_bus_error *err):
    cdef PyObject *call_ptr = <PyObject*>userdata
    cdef Call call = <Call>call_ptr
    cdef Message message = Message()

    message.import_sd_bus_message(m)


    # process response, refer to async_polkit_callback in
    # systemd-232/src/shared/bus-util.c

    # wake up sleeping call

    call.wake()

    return 0

cdef class Call:
    cdef Message message
    cdef Service service
    cdef sdbus_h.sd_bus_slot *_slot
    cdef object event
    cdef object response

    def __init__(self, Service service, address, path, interface, method, args=None):

        self.event = Event(loop=service.loop)
        self.service = service
        self.response = None
        self.message = Message()
        self.message.new_method_call(service, address, path, interface, method)

        if args:
            for arg in args:
                signature = dbus_signature(arg)
                self.message.append(signature, arg)

    def send(self, stdint.uint64_t timout_ms):
        cdef int ret
        self.event.clear()

        ret = sdbus_h.sd_bus_call_async(self.service.bus, &self._slot,
                self.message.message, call_callback, <void *>self,
                timout_ms*1000)
        if ret < 0:
            raise SdbusError(f"Failed to send call: {errorcode[-ret]}", -ret)

    cdef wake(self):
        self.event.set()

    def wait_for_response(self):
        """A couroutine that will wait for a response."""
        return self.event.wait()

    def get_response(self):
        """Return the response."""
        return self.response
