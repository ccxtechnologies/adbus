# == Copyright: 2017, CCX Technologies

cdef class Error:
    cdef sdbus_h.sd_bus_error *_e

    def __cinit__(self):
        self._e = NULL

    cdef import_sd_bus_error(self, sdbus_h.sd_bus_error *error):
        self._e = error

    cdef reply_from_exception(self, sdbus_h.sd_bus_message *call,
            Exception exception):
        cdef int errno
        cdef int ret

        #NOTE: sd_bus uses the System.Error prefix for general purpose errors
        cdef bytes err_name = b"System.Error." + \
            exception.__class__.__name__.encode('utf-8')

        cdef bytes err_message = str(exception).encode('utf-8')

        errno = sdbus_h.sd_bus_error_set(self._e, err_name, err_message)

        ret = sdbus_h.sd_bus_reply_method_errno(call, errno, self._e)
        if ret < 0:
            raise SdbusError(f"Failed to send error reply: {errorcode[-ret]}", -ret)
