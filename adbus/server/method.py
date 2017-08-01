# Copyright: 2017, CCX Technologies
"""D-Bus Method"""

import functools
import inspect

from .. import sdbus


class Method:
    """Provides an interface between a D-Bus and a Python Method or Function.

    Though this class can be used on its own it is intended to be used with
    the method decorator applied to methods on a class that is a subclass of
    the main Object type.

    Args:
        callback (function): function that will be called when
            D-Bus method is called, it should use new style type
            annotations to define the types of all arguments,
            and the return value, ie. function(x: int, y: str) -> bool:
            if no type is defined a D-Bus Variant will be used
        name (str): optional, name of the method advertised on the D-Bus
            if not set then will use the callback name
        depreciated (bool): optional, if true object is labelled
            as depreciated in the introspect XML data
        hidden (bool): optional, if true object won't be added
            to the introspect XML data
        unprivileged (bool): optional, indicates that this method
            may have to ask the user for authentication before
            executing, which may take a little while
        camel_convert (bool): optional, D-Bus method and property
            names are typically defined in Camel Case, but Python
            methods and arguments are typically defined in Snake
            Case, if this is set the cases will be automatically
            converted between the two
        dont_block (bool): optional, if true the method call will not
            block on the D-Bus, **a value will never be returned**

    Raises:
        BusError: if an error occurs during initialization
    """

    def __init__(
        self,
        callback,
        name=None,
        depreciated=False,
        hidden=False,
        unprivileged=False,
        camel_convert=True,
        dont_block=False,
    ):
        if not name:
            name = callback.__name__

        self.callback = callback
        """Function called when this method is called."""

        if camel_convert:
            self.dbus_name = sdbus.snake_to_camel(name)
            """Method name advertised on the D-Bus."""
        else:
            self.dbus_name = name

        self.depreciated = depreciated
        self.hidden = hidden
        self.unprivileged = unprivileged

        self.arg_signature = ''
        sig = inspect.signature(callback)
        for param in sig.parameters.values():
            if param.annotation != inspect.Parameter.empty:
                self.arg_signature += sdbus.dbus_signature(param.annotation)
            else:
                self.arg_signature += sdbus.variant_signature()

        self.dont_block = dont_block
        if self.dont_block:
            self.return_signature = ''
        elif sig.return_annotation != inspect.Parameter.empty:
            self.return_signature = sdbus.dbus_signature(sig.return_annotation)
        else:
            self.return_signature = sdbus.variant_signature()

    def __call__(self, *args, **kwargs):
        return self.callback(*args, **kwargs)

    def vt(self, instance=None):
        """Interface to sd-bus library"""
        if instance:
            arg_signature = self.arg_signature[1:]
            callback = functools.partial(self.callback, instance)
        else:
            arg_signature = self.arg_signature
            callback = self.callback

        return sdbus.Method(
            self.dbus_name, callback, arg_signature, self.return_signature,
            self.depreciated, self.hidden, self.unprivileged, self.dont_block
        )


def method(
    name=None,
    depreciated=False,
    hidden=False,
    unprivileged=False,
    camel_convert=True
):
    """D-Bus Method Decorator.

    Note:
        The decorated method should use new style type annotations
        to define the types of all arguments, and the return value,
        ie. function(x: int, y: str) -> bool:
        if no type is defined a D-Bus Variant will be used

    Args:
        name (str): optional, if set this name will be used on
            the D-Bus, instead of the decorated function's name
        depreciated (bool): optional, if true object is labelled
            as depreciated in the introspect XML data
        hidden (bool): optional, if true object won't be added
            to the introspect XML data
        unprivileged (bool): optional, indicates that this method
            may have to ask the user for authentication before
            executing, which may take a little while
        camel_convert (bool): optional, D-Bus method and property
            names are typically defined in Camel Case, but Python
            methods and arguments are typically defined in Snake
            Case, if this is set the cases will be automatically
            converted between the two

    Returns:
        Instantiated Method, which can be used to replace a method
        or function.
    """

    def wrapper(function):
        return Method(
            function, name, depreciated, hidden, unprivileged, camel_convert
        )

    return wrapper
