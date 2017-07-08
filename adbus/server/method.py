# Copyright: 2017, CCX Technologies

"""D-Bus Method"""

import functools
from .. import sdbus

class Method:
    """D-Bus Method"""

    def __init__(self, name, callback, arg_signature='', return_signature='',
            deprectiated=False, hidden=False, unprivledged=False):
        self.func = callback
        self.sdbus = sdbus.Method(name, callback, arg_signature, return_signature,
            deprectiated, hidden, unprivledged)

    def __call__(self, *args, **kwargs):
        return self.func(*args, **kwargs)

def method(name=None, deprectiated=False, hidden=False, unprivledged=False):

    @functools.wraps(func)
    def wrapper():
        if not name:
            name = func.__name__
        return  Method()

    return helper

