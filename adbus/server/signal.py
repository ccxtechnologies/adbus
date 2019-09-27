# Copyright: 2017, CCX Technologies
"""D-Bus Signal"""

from .. import sdbus


class Signal:
    """Provides a method to emit a signal via D-Bus.

    This class is to be used as a Decorator for signals in
    an adbus.server.Object which will be exported via the D-Bus.

    Args:
        name (str): optional, signal name used in the D-Bus, if None the
            signal's label will be used
        deprecated (bool): optional, if true object is labelled
            as deprecated in the introspect XML data
        hidden (bool): optional, if true object won't be added
            to the introspect XML data
        camel_convert (bool): optional, D-Bus method and property
            names are typically defined in Camel Case, but Python
            methods and arguments are typically defined in Snake
            Case, if this is set the cases will be automatically
            converted between the two
    """
    def __init__(
            self,
            name=None,
            deprecated=False,
            hidden=False,
            camel_convert=True
    ):

        self.dbus_name = name
        self.deprecated = deprecated
        self.hidden = hidden
        self.camel_convert = camel_convert

    def __get__(self, instance, owner):
        raise RuntimeError("Can't read from a signal")

    def __set__(self, instance, value):
        signal = instance.__dict__[self.py_name]

        if isinstance(self.dbus_signature, list):
            signal.emit(*value)
        else:
            signal.emit(value)

    def __set_name__(self, owner, name):
        self.py_name = name

        try:
            signature = iter(owner.__annotations__[name])
        except TypeError:
            self.dbus_signature = (
                    sdbus.dbus_signature(owner.__annotations__[name]),
            )
        except KeyError:
            self.dbus_signature = sdbus.variant_signature()
        else:
            try:
                self.dbus_signature = [
                        sdbus.dbus_signature(s) for s in signature
                ]
            except RuntimeError:
                # this is a work around for an issue with the
                # typing library on Python version 3.7 creating an
                # unusable iterator from typing.List[int]
                self.dbus_signature = (
                        sdbus.dbus_signature(owner.__annotations__[name]),
                )

        if not self.dbus_name:
            self.dbus_name = name

        if self.camel_convert:
            self.dbus_name = sdbus.snake_to_camel(self.dbus_name)

    def vt(self, instance):
        signal = sdbus.Signal(
                self.dbus_name, self.dbus_signature, self.deprecated,
                self.hidden
        )
        instance.__dict__[self.py_name] = signal
        return signal
