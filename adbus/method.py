# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""D-Bus Method"""

from . import _sdbus

class Method:
    """D-Bus Method"""

    def __init__(self, name, callback, arg_types='', return_type='',
            deprectiated=False, hidden=False, unprivledged=False):
        self.sdbus = _sdbus.Method(name, callback, arg_types, return_type,
            deprectiated, hidden, unprivledged)
