# Copyright: 2017, CCX Technologies
"""D-Bus Method"""

import functools
from inspect import signature

from .. import sdbus
from .. import exceptions


class Method:
    """Provides an interface between a D-Bus and a Python Method or Function.

    Though this class can be used on its own it is intended to be used with
    the method decorator applied to methods on a class that is a subclass of
    the main Object type.
    """

    def __init__(
        self,
        callback,
        name=None,
        depreciated=False,
        hidden=False,
        unprivleged=False,
        camel_convert=True
    ):
        """D-Bus Method Initialization.

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
            unprivleged (bool): optional, indicates that this method
                may have to ask the user for authentication before
                executing, which may take a little while
            camel_convert (bool): optional, D-Bus method and property
                names are typically defined in Camel Case, but Python
                methods and arguments are typically defined in Snake
                Case, if this is set the cases will be automatically
                converted between the two

        Raises:
            BusError: if an error occurs during initialization
        """

        if not name:
            name = callback.__name__

        self.callback = callback
        """Function called when this method is called."""

        if camel_convert:
            self.name = sdbus.snake_to_camel(name)
            """Method name advertised on the D-Bus."""
        else:
            self.name = name

        self.depreciated = depreciated
        self.hidden = hidden
        self.unprivleged = unprivleged

        self.arg_signature = ''
        self.return_signature = ''
        for arg_name, arg_type in callback.__annotations__.items():
            if arg_name == 'return':
                self.return_signature = sdbus.object_signature(arg_type)
            else:
                self.arg_signature += sdbus.object_signature(arg_type)

    def __call__(self, *args, **kwargs):
        return self.callback(*args, **kwargs)

    def vt(self, instance=None):
        """Interface to sd-bus library"""
        if instance:
            callback = functools.partial(self.callback, instance)
        else:
            callback = self.callback

        num_args = len(signature(callback).parameters)
        num_sig = len(self.arg_signature)
        if num_args != num_sig:
            print(signature(callback).parameters)
            raise exceptions.BusError(
                f"{num_args} args in method, but {num_sig} args in sig"
            )

        return sdbus.Method(
            self.name, callback, self.arg_signature, self.return_signature,
            self.depreciated, self.hidden, self.unprivleged
        )


def method(
    name=None,
    depreciated=False,
    hidden=False,
    unprivleged=False,
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
        unprivleged (bool): optional, indicates that this method
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
            function, name, depreciated, hidden, unprivleged, camel_convert
        )

    return wrapper
