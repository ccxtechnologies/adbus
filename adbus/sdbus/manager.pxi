# == Copyright: 2017-2026, CCX Technologies
#cython: language_level=3

cdef class Manager:
    cdef sdbus_h.sd_bus *bus
    cdef sdbus_h.sd_bus_slot *_slot
    cdef bytes path

    def __cinit__(self, service, path):
        self.path = path.encode()
        self.bus = (<Service>service).bus

        ret = sdbus_h.sd_bus_add_object_manager(self.bus, &self._slot, self.path)
        if ret < 0:
            raise SdbusError(f"Failed to add manager: {errorcode[-ret]}", -ret)

    def emit_interfaces_added(self, path, interfaces):
        cdef int ret
        cdef bytes b_path = path.encode()
        cdef list b_interfaces = [i.encode() for i in interfaces]
        cdef char **c_interfaces = <char **>PyMem_Malloc((len(b_interfaces) + 1) * sizeof(char *))

        try:
            for idx, iface in enumerate(b_interfaces):
                c_interfaces[idx] = iface
            c_interfaces[len(b_interfaces)] = NULL

            ret = sdbus_h.sd_bus_emit_interfaces_added_strv(
                self.bus, b_path, c_interfaces
            )
            if ret < 0:
                raise SdbusError(f"Failed to emit InterfacesAdded: {errorcode[-ret]}", -ret)
        finally:
            PyMem_Free(c_interfaces)

    def emit_interfaces_removed(self, path, interfaces):
        cdef int ret
        cdef bytes b_path = path.encode()
        cdef list b_interfaces = [i.encode() for i in interfaces]
        cdef char **c_interfaces = <char **>PyMem_Malloc((len(b_interfaces) + 1) * sizeof(char *))

        try:
            for idx, iface in enumerate(b_interfaces):
                c_interfaces[idx] = iface
            c_interfaces[len(b_interfaces)] = NULL

            ret = sdbus_h.sd_bus_emit_interfaces_removed_strv(
                self.bus, b_path, c_interfaces
            )
            if ret < 0:
                raise SdbusError(f"Failed to emit InterfacesRemoved: {errorcode[-ret]}", -ret)
        finally:
            PyMem_Free(c_interfaces)

    def emit_object_added(self, path):
        cdef bytes b_path = path.encode()
        cdef int ret = sdbus_h.sd_bus_emit_object_added(self.bus, b_path)
        if ret < 0:
            raise SdbusError(f"Failed to emit ObjectAdded: {errorcode[-ret]}", -ret)

    def emit_object_removed(self, path):
        cdef bytes b_path = path.encode()
        cdef int ret = sdbus_h.sd_bus_emit_object_removed(self.bus, b_path)
        if ret < 0:
            raise SdbusError(f"Failed to emit ObjectRemoved: {errorcode[-ret]}", -ret)

    def __dealloc__(self):
        self._slot = sdbus_h.sd_bus_slot_unref(self._slot)
