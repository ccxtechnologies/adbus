# Copyright: 2017, CCX Technologies

"""D-Bus Property"""

from .. import sdbus

class Property:
    """D-Bus Property Descriptor."""

    def __init__(self, name, py_object, attr_name, signature='', read_only=False,
            deprectiated=False, hidden=False, unprivledged=False,
            emits_constant=False, emits_change=False, emits_invalidation=False):
        self.sdbus = sdbus.Property(name, py_object, attr_name, signature, read_only,
            deprectiated, hidden, unprivledged, emits_constant, emits_change,
            emits_invalidation)

    def __get__(self, instance, owner):
        return instance.__dict__[self.name]

    def __set__(self, instance, value):
        if not isinstance(value, int):
            raise ValueError(f'expecting integer in {self.name}')
        instance.__dict__[self.name] = value

    # this is the new initializer:
    def __set_name__(self, owner, name):
        self.name = name

    def emit_changed(self):
        self.sdbus.emits_change()
