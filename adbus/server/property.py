# Copyright: 2017, Charles Eidsness

"""D-Bus Property"""

from .. import sdbus

class Property:
    """D-Bus Property"""

    def __init__(self, name, py_object, attr_name, signature='', read_only=False,
            deprectiated=False, hidden=False, unprivledged=False,
            emits_constant=False, emits_change=False, emits_invalidation=False):
        self.sdbus = sdbus.Property(name, py_object, attr_name, signature, read_only,
            deprectiated, hidden, unprivledged, emits_constant, emits_change,
            emits_invalidation)
