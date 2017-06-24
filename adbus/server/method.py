# Copyright: 2017, Charles Eidsness

"""D-Bus Method"""

from .. import sdbus

class Method:
    """D-Bus Method"""

    def __init__(self, name, callback, arg_signature='', return_signature='',
            deprectiated=False, hidden=False, unprivledged=False):
        self.sdbus = sdbus.Method(name, callback, arg_signature, return_signature,
            deprectiated, hidden, unprivledged)
