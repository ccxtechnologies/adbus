# Copyright: 2017, CCX Technologies

"""D-Bus Service"""

from .. import sdbus
import asyncio

class Service:
    """Serves objects onto a D-Bus, runs within an asyncio loop.

    This is a class can be used to create a server that attaches the to
    D-Bus and serves objects. To process requests it must be run within an
    asyncio loop.

    Objects are added by initializing them with an instantiated service.
    More than one object can be attached to a service as long as they
    don't have the same path.
    """

    def __cinit__(self, name, loop=None, bus='system',
            replace_existing=False, allow_replacement=False, queue=False):
        """D-Bus Service Initilization.

        Attributes:
            name (str): name to be used on the D-Bus, ie. org.test
            loop: optional, asyncio loop to attach to, if not
                defined will use asyncio.get_event_loop()
            bus (str): optional, D-Bus to attach to either 'system', or 'session'
            replace_existing (bool): optional, if true and there is a
                D-Bus service with the same name try to replace it
            allow_replacement (bool): optional, if true and another service
                tries to use or name let it
            queue (bool): optional, if name in use put ourselves in the name
                queue, will get name once the existing service relenquishes it

        Raises:
            BusError: if an error occurs during initialization

        """

        try:
            self.sdbus = sdbus.Service(name, bus, if_name_in_use)
            """Interface to sd-bus library"""
        except sdbus.BusError as exc:
            raise BusError(str(exc)) from exc

        # add a reader, so we process dbus message when they come in
        bus_fd = self.sdbus.get_fd()
        if bus_fd <= 0:
            raise self.BusError("Failed to read sd-bus fd")

        if not loop:
            loop = asyncio.get_event_loop()

        loop.add_reader(bus_fd, self.sdbus.process)
