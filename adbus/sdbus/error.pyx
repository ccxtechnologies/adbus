# == Copyright: 2017, CCX Technologies

cdef class Error:
    cdef sdbus_h.sd_bus_error *_e

    def __cinit__(self):
        self._e = NULL

    cdef import_sd_bus_error(self, sdbus_h.sd_bus_error *error):
        self._e = error

    cdef int from_exception(self, exception):
        #NOTE: sd_bus uses the System.Error prefix for general purpose errors
        cdef bytes err_name = b"System.Error." + \
            exception.__class__.__name__.encode('utf-8')
        cdef bytes err_message = str(exception).encode('utf-8')
        return sdbus_h.sd_bus_error_set(self._e, err_name, err_message)

