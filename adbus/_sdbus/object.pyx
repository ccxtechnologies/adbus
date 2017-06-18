# == Copyright: 2017, Charles Eidsness

cdef class Object:
    cdef _sdbus_h.sd_bus_slot *_slot
    cdef _sdbus_h.sd_bus_vtable *_vtable
    cdef void **_userdata
    cdef bytes path
    cdef bytes interface
    cdef list vtable
    cdef list exceptions

    def __cinit__(self, service, path, interface, vtable, deprectiated=False, hidden=False):
        
        self.vtable = vtable
        self.path = path.encode()
        self.interface = interface.encode()
        self.exceptions = (<Service>service).exceptions

        self._malloc()
        self._init_vtable(deprectiated, hidden)

        for i, v in enumerate(vtable):
            if type(v) == Method:
                (<Method>v).populate_vtable(&self._vtable[i+1])
                (<Method>v).exceptions = self.exceptions
                self._vtable[i+1].x.method.offset = i*sizeof(self._userdata[0]) 
                self._userdata[i] = (<Method>v).userdata

        self._register_vtable(service, self.path, self.interface)
    
    def __dealloc__(self):
        self._slot = _sdbus_h.sd_bus_slot_unref(self._slot)
        PyMem_Free(self._vtable)
        PyMem_Free(self._userdata)

    def _malloc(self):
        length = len(self.vtable)

        self._vtable = <_sdbus_h.sd_bus_vtable *>PyMem_Malloc(
                (length+2)*sizeof(_sdbus_h.sd_bus_vtable))
        if not self._vtable:
            raise MemoryError("Failed to allocate vtable")

        self._userdata = <void **>PyMem_Malloc(length*sizeof(void*))
        if not self._userdata:
            raise MemoryError("Failed to allocate userdata")

    def _init_vtable(self, deprectiated, hidden):
        length = len(self.vtable)

        self._vtable[0].type = _sdbus_h._SD_BUS_VTABLE_START
        self._vtable[0].x.start.element_size = sizeof(self._vtable[0])
        self._vtable[0].flags = 0

        if deprectiated:
            self._vtable[0].flags |= _sdbus_h.SD_BUS_VTABLE_DEPRECATED

        if hidden:
            self._vtable[0].flags |= _sdbus_h.SD_BUS_VTABLE_HIDDEN

        self._vtable[length+1].type = _sdbus_h._SD_BUS_VTABLE_END
        self._vtable[length+1].flags = 0

    def _register_vtable(self, service, path, interface):
        e = _sdbus_h.sd_bus_add_object_vtable((<Service>service).bus, 
                &self._slot, path, interface, self._vtable, self._userdata)
        if e < 0:
            raise SdbusError(f"Failed to register vtable: {errorcode[-e]}")

