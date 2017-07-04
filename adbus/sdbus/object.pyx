# == Copyright: 2017, Charles Eidsness

cdef class Object:
    cdef sdbus_h.sd_bus *bus
    cdef sdbus_h.sd_bus_slot *_slot
    cdef sdbus_h.sd_bus_vtable *_vtable
    cdef void **_userdata
    cdef bytes path
    cdef bytes interface
    cdef list vtable
    cdef list exceptions

    def __cinit__(self, service, path, interface, vtable,
            deprectiated=False, hidden=False):
        self.vtable = vtable
        self.path = path.encode()
        self.interface = interface.encode()
        self.exceptions = (<Service>service).exceptions
        self.bus = (<Service>service).bus

        self._malloc()
        self._init_vtable(deprectiated, hidden)

        for i, v in enumerate(vtable):
            if type(v) == Method:
                (<Method>v).set_object(self)
                (<Method>v).populate_vtable(&self._vtable[i+1])
                (<Method>v).exceptions = self.exceptions
                self._vtable[i+1].x.method.offset = i*sizeof(self._userdata[0])
                self._userdata[i] = (<Method>v).userdata

            elif type(v) == Property:
                (<Property>v).set_object(self)
                (<Property>v).populate_vtable(&self._vtable[i+1])
                (<Property>v).exceptions = self.exceptions
                self._vtable[i+1].x.method.offset = i*sizeof(self._userdata[0])
                self._userdata[i] = (<Property>v).userdata

            elif type(v) == Signal:
                (<Signal>v).set_object(self)
                (<Signal>v).populate_vtable(&self._vtable[i+1])

        self._register_vtable()

    def __dealloc__(self):
        self._slot = sdbus_h.sd_bus_slot_unref(self._slot)
        PyMem_Free(self._vtable)
        PyMem_Free(self._userdata)

    def _malloc(self):
        length = len(self.vtable)

        self._vtable = <sdbus_h.sd_bus_vtable *>PyMem_Malloc(
                (length+2)*sizeof(sdbus_h.sd_bus_vtable))
        if not self._vtable:
            raise MemoryError("Failed to allocate vtable")

        self._userdata = <void **>PyMem_Malloc(length*sizeof(void*))
        if not self._userdata:
            raise MemoryError("Failed to allocate userdata")

    def _init_vtable(self, deprectiated, hidden):
        length = len(self.vtable)

        self._vtable[0].type = sdbus_h._SD_BUS_VTABLE_START
        self._vtable[0].x.start.element_size = sizeof(self._vtable[0])
        self._vtable[0].flags = 0

        if deprectiated:
            self._vtable[0].flags |= sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self._vtable[0].flags |= sdbus_h.SD_BUS_VTABLE_HIDDEN

        self._vtable[length+1].type = sdbus_h._SD_BUS_VTABLE_END
        self._vtable[length+1].flags = 0

    def _register_vtable(self):
        ret = sdbus_h.sd_bus_add_object_vtable(self.bus, &self._slot,
                self.path, self.interface, self._vtable, self._userdata)
        if ret < 0:
            raise SdbusError(f"Failed to register vtable: {errorcode[-ret]}", -ret)

    def emit_properties_changed(self, properties):
        cdef int ret
        cdef list property_names = [p.get_name() for p in properties]
        cdef char **names = <char**>PyMem_Malloc((len(properties)+1)*sizeof(char*))
        if not names:
            raise MemoryError("Failed to allocate names")

        names[len(properties)] = NULL
        for i, property in enumerate(property_names):
            names[i] = <bytes>property

        ret = sdbus_h.sd_bus_emit_properties_changed_strv(self.bus, self.path,
            self.interface, names)
        if ret < 0:
            raise SdbusError(f"Failed to emit changed: {errorcode[-ret]}", -ret)

        PyMem_Free(names)
