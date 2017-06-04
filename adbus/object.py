# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""D-Bus Object"""

from . import _sdbus

class Object:
    """D-Bus Object / Node"""

    def __init__(self, service, path, interface, vtable, 
            deprectiated=False, hidden=False):
        self.sdbus = _sdbus.Object(service.sdbus, path, interface,
                [v.sdbus for v in vtable], deprectiated, hidden)
