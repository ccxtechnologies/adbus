# Copyright: 2017, Charles Eidsness

"""D-Bus Signal"""

from .. import sdbus

class Signal:
    """D-Bus Signal"""

    def __init__(self, name, signature='', deprectiated=False, hidden=False):
        self.sdbus = sdbus.Signal(name, signature, deprectiated, hidden)

    def emit(self, value):
        self.sdbus.emit(value)
