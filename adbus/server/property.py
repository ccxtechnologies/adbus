# Copyright: 2017, CCX Technologies
"""D-Bus Property"""

import functools
import inspect

from .. import sdbus


class Property:
    """D-Bus Property Descriptor."""

    def __init__(
        self,
        default=None,
        name=None,
        read_only=False,
        depreciated=False,
        hidden=False,
        unprivileged=False,
        emits_constant=False,
        emits_change=True,
        emits_invalidation=False,
        camel_convert=True,
    ):

        self.default = default
        self.name = name
        """Method name advertised on the D-Bus."""
        self.read_only = read_only
        self.depreciated = depreciated
        self.hidden = hidden
        self.unprivileged = unprivileged
        self.emits_constant = emits_constant
        self.emits_change = emits_change
        self.emits_invalidation = emits_invalidation
        self.camel_convert = camel_convert

    def __get__(self, instance, owner):
        try:
            return instance.__dict__[self.key]
        except KeyError:
            return self.default

    def __set__(self, instance, value):
        instance.__dict__[self.key] = value
        instance.emit_property_changed(self.name)

    def __set_name__(self, owner, name):
        self.key = name

        try:
            self.dbus_signature = sdbus.dbus_signature(owner.__annotations__[name])
        except KeyError:
            self.dbus_signature = sdbus.variant_signature()

        if not self.name:
            self.name = name

        if self.camel_convert:
            self.name = sdbus.snake_to_camel(name)
        else:
            self.name = name

    def vt(self, instance):
        """Interface to sd-bus library"""
        return sdbus.Property(
            self.name, instance, self.key, self.dbus_signature, self.read_only,
            self.depreciated, self.hidden, self.unprivileged,
            self.emits_constant, self.emits_change, self.emits_invalidation
        )
