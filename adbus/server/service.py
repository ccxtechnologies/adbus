# Copyright: 2017, Charles Eidsness

"""D-Bus Service"""

from .. import sdbus

class Service:
    """D-Bus Service"""

    class BusError(Exception):
        """Adbus Service Exception"""
        pass

    def __init__(self, name, loop, system=False):
        self.sdbus = sdbus.Service(name, system)

        # add a reader, so we process dbus message when they come in
        bus_fd = self.sdbus.get_fd()
        if bus_fd <= 0:
            raise self.BusError("Failed to read sd-bus fd")

        loop.add_reader(bus_fd, self.sdbus.process)

