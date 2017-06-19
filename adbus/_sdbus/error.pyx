# == Copyright: 2017, Charles Eidsness

cdef class Error:
    cdef _sdbus_h.sd_bus_error *_e

    def __cinit__(self):
        self._e = NULL

    cdef import_sd_bus_error(self, _sdbus_h.sd_bus_error *error):
        self._e = error

    cdef int from_exception(self, exception):
        #NOTE: sd_bus uses the System.Error prefix for general purpose errors
        cdef bytes err_name = b"System.Error." + exception.__class__.__name__.encode('utf-8')
        cdef bytes err_message = str(exception).encode('utf-8')
        return _sdbus_h.sd_bus_error_set(self._e, err_name, err_message)
