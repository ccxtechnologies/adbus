# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""D-Bus Service"""

from . import _sdbus

class Service:
    """D-Bus Service"""

    def __init__(self, name, system=False):
        self.sdbus = _sdbus.Service(name, system)

    async def process(self):
        """Wait for and then process the next D-Bus transaction"""
        while True:
            if not self.sdbus.bus_process():
                self.sdbus.bus_wait()
