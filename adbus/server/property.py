# Copyright: 2017, CCX Technologies
"""D-Bus Property"""

from .. import sdbus


class Property:
    """Provides an interface between a D-Bus and a Python Property.

    This class is to be used as a Decorator for arguments (properties) in
    an adbus.server.Object which will be exported via the D-Bus.

    Args:
        default: optional, default setting for the property
        name (str): optional, property name used in the D-Bus, if None the
            property's label will be used
        read_only (bool): if True the property can only be read via D-Bus
            (but can still be set locally)
        constant (bool): if True the property can only be read via D-Bus or
            locally, it also advertises constant in the introspect XML data
        deprecated (bool): optional, if true object is labelled
            as deprecated in the introspect XML data
        hidden (bool): optional, if true object won't be added
            to the introspect XML data
        unprivileged (bool): optional, indicates that this method
            may have to ask the user for authentication before
            executing, which may take a little while
        emits_change (bool): optional, when changed emits a signal with
            the new value
        emits_invalidation (bool): optional, when changed emits a signal but
            doesn't provide the new value, can be used for large, complex
            properties, overrides emits_change if it's set
        camel_convert (bool): optional, D-Bus method and property
            names are typically defined in Camel Case, but Python
            methods and arguments are typically defined in Snake
            Case, if this is set the cases will be automatically
            converted between the two
    """

    def __init__(
            self,
            default=None,
            name=None,
            read_only=False,
            constant=False,
            deprecated=False,
            hidden=False,
            unprivileged=False,
            emits_change=True,
            emits_invalidation=False,
            camel_convert=True,
    ):

        self.default = default
        self.dbus_name = name
        self.read_only = read_only or constant
        self.constant = constant
        self.deprecated = deprecated
        self.hidden = hidden
        self.unprivileged = unprivileged
        self.emits_change = emits_change and (not emits_invalidation)
        self.emits_invalidation = emits_invalidation
        self.camel_convert = camel_convert

    def __get__(self, instance, owner):
        try:
            return instance.__dict__[self.py_name]
        except KeyError:
            return self.default

    def __set__(self, instance, value):
        if self.constant:
            raise ValueError("Can't change the value of a constant.")

        if getattr(instance, self.py_name) != value:
            instance.__dict__[self.py_name] = value
            self.emit_changed(instance)

    def emit_changed(self, instance):
        if self.emits_change or self.emits_invalidation:
            instance.emit_property_changed(self.dbus_name)

    def __set_name__(self, owner, name):
        self.py_name = name

        try:
            self.dbus_signature = sdbus.dbus_signature(
                    owner.__annotations__[name]
            )
        except KeyError:
            self.dbus_signature = sdbus.variant_signature()

        if not self.dbus_name:
            self.dbus_name = name

        if self.camel_convert:
            self.dbus_name = sdbus.snake_to_camel(self.dbus_name)

    def vt(self, instance):
        """Interface to sd-bus library"""
        return sdbus.Property(
                self.dbus_name, instance, self.py_name, self.dbus_signature,
                self.read_only, self.deprecated, self.hidden,
                self.unprivileged, self.constant, self.emits_change,
                self.emits_invalidation
        )
