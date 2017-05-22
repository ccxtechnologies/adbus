# == Copyright: 2017, Charles Eidsness

cdef class Object:
    cdef _sdbus_h.sd_bus_slot *_slot
    cdef _sdbus_h.sd_bus_vtable *_vtable
    cdef void **_userdata;

    def __cinit__(self, service, path, interface, vtable):

        # -- Allocate Memory --
        self._vtable = <_sdbus_h.sd_bus_vtable *>PyMem_Malloc((len(vtable)+2)*
                sizeof(_sdbus_h.sd_bus_vtable))
        if not self._vtable:
            raise MemoryError("Failed to allocate vtable")

        self._userdata = <void **>PyMem_Malloc(len(vtable)*
                sizeof(void*))
        if not self._userdata:
            raise MemoryError("Failed to allocate userdata")

        # -- Populate vtable --
        self._vtable[0].flags = _sdbus_h._SD_BUS_VTABLE_START
        self._vtable[0].x.start.element_size = sizeof(_sdbus_h.sd_bus_vtable)

        self._vtable[len(vtable)+1].flags = _sdbus_h._SD_BUS_VTABLE_END

        for i in range(0, len(vtable)):
            if type(vtable[i]) == Method:
                self._vtable[i+1].flags = (<Method>vtable[i]).flags
                memcpy(&self._vtable[i].x, &(<Method>vtable[i]).x, 
                        sizeof(_sdbus_h.sd_bus_vtable_method))
                self._vtable[i+1].x.method.offset = i
                self._userdata[i] = (<Method>vtable[i]).userdata
            else:
                raise SdbusError(f"Unknown vtable type {type(vtable[i])}")
            
        # -- Register vtable --
        r = _sdbus_h.sd_bus_add_object_vtable((<Service>service)._bus, 
                &self._slot, path, interface, self._vtable, self._userdata)
        if r < 0:
            raise SdbusError(f"Failed to add vtable: {r}")

    def __dealloc__(self):
        self._slot = _sdbus_h.sd_bus_slot_unref(self._slot)
        PyMem_Free(self._vtable)
        PyMem_Free(self._userdata)
