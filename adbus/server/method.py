# Copyright: 2017, CCX Technologies

"""D-Bus Method"""

import functools
from inspect import signature

from .. import sdbus
from .. import exceptions

class Method:
    """D-Bus Method"""

    def __init__(self, name, callback, deprectiated=False, hidden=False, unprivledged=False,
            camel_convert=True):

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
            raise exceptions.BusError("Missing type annotations for some arguments")

        self.sdbus = sdbus.Method(self.name, self.callback, arg_signature,
                return_signature, deprectiated, hidden, unprivledged)
        """Interface to sd-bus library"""

    def __call__(self, *args, **kwargs):
        return self.callback(*args, **kwargs)

def method(name=None, deprectiated=False, hidden=False, unprivledged=False):

    @functools.wraps(func)
    def wrapper():
        if not name:
            name = func.__name__
        return  Method(name, func, deprectiated, hidden, unprivledged)

    return wrapper

