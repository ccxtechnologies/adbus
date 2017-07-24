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
            name,
            callback,
            depreciated=False,
            hidden=False,
            unprivleged=False,
            camel_convert=True
    ):
        """D-Bus Method Initialization.

        Args:
            name (str): name of the method advertised on the D-Bus
            callback (function): function that will be called when
                D-Bus method is called, it **must** use new style type
                annotations to define the types of all arguments,
                and the return value, ie. function(x: int, y: str) -> bool:
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

        Raises:
            BusError: if an error occurs during initialization
        """

        self.callback = callback
        """Function called when this method is called."""

        if camel_convert:
            self.name = sdbus.snake_to_camel(name)
            """Method name advertised on the D-Bus."""
        else:
            self.name = name

        arg_signature = []
        return_signature = b''
        for arg_name, arg_type in callback.__annotations__.items():
            if arg_name == 'return':
                return_signature = sdbus.object_signature(arg_type)
            else:
                arg_signature.append(sdbus.object_signature(arg_type))

        if len(signature(callback.parameters)) != len(arg_signature):
            raise exceptions.BusError(
                    "Missing type annotations for some arguments"
            )

        self.sdbus = sdbus.Method(
                self.name, self.callback, arg_signature, return_signature,
                depreciated, hidden, unprivleged
        )
        """Interface to sd-bus library"""

    def __call__(self, *args, **kwargs):
        return self.callback(*args, **kwargs)


def method(
        name=None,
        deprectiated=False,
        hidden=False,
        unprivleged=False,
        camel_convert=True
):
    """D-Bus Method Decorator.

    Note:
        The decorated method **must** use new style type annotations
        to define the types of all arguments, and the return value,
        ie. function(x: int, y: str) -> bool:

    Args:
        name (str): optional, if set this name will be used on
            the D-Bus, instead of the decorated function's name
        depreciated (bool): optional, if true object is labelled
            as depreciated in the introspect xml data
        hidden (bool): optional, if true object won't be added
            to the introspect xml data
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

    @functools.wraps(func)
    def wrapper():
        if not name:
            name = func.__name__
        return Method(
                name, func, deprectiated, hidden, unprivleged, camel_convert
        )

    return wrapper
