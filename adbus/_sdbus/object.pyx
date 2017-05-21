# == Copyright: 2017, Charles Eidsness

cimport _sdbus_h
from cpython.mem cimport PyMem_Malloc
from cpython.mem cimport PyMem_Free

cdef class Object:
    cdef _sdbus_h.sd_bus_slot *_slot
    cdef _sdbus_h.sd_bus_vtable *_vtable
    cdef void **_userdata;

    def __cinit__(self, service, path, interface, vtable):

        cdef int vtable_len = len(vtable) + 2

        self._vtable = <_sdbus_h.sd_bus_vtable *>PyMem_Malloc(vtable_len*
                sizeof(_sdbus_h.sd_bus_vtable))
        if not self._vtable:
            raise MemoryError("Failed to allocate vtable")

        self._userdata = <void **>PyMem_Malloc(vtable_len*
                sizeof(void*))
        if not self._userdata:
            raise MemoryError("Failed to allocate vtable")


    def __dealloc__(self):
        self._slot = sd_bus_slot_unref(self._slot)
        PyMem_Free(self._vtable)
        PyMem_Free(self._userdata)

