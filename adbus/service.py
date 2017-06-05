# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""D-Bus Service"""

from . import _sdbus

class Service:
    """D-Bus Service"""

    def __init__(self, name, system=False):
        self.sdbus = _sdbus.Service(name, system)

    async def mainloop(self):
        """Wait for and then process the next D-Bus transaction"""
        while True:
            if not self.sdbus.process():
                self.sdbus.wait()

    def add(self, path, interface, vtable, deprectiated=False, hidden=False):
        """Add an object plus vtable to the Service."""
        return self.sdbus.add(path, interface, [v.sdbus for v in vtable], deprectiated, hidden)

    def remove(self, obj):
        """Remove an object from the Service."""
        self.sdbus.remove(obj)
