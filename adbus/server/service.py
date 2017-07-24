# Copyright: 2017, CCX Technologies
"""D-Bus Service"""

from .. import sdbus
from .. import exceptions
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

    def __init__(
        self,
        name,
        loop=None,
        bus='system',
        replace_existing=False,
        allow_replacement=False,
        name_queue=False
    ):
        """D-Bus Service Initialization.

        Args:
            name (str): name to be used on the D-Bus, ie. org.test
            loop: optional, asyncio loop to attach to, if not
                defined will use asyncio.get_event_loop()
            bus (str): optional, Bus to attach to either 'system', or 'session'
            replace_existing (bool): optional, if true and there is a
                D-Bus service with the same name, try to replace it
            allow_replacement (bool): optional, if true and another service
                tries to steal our name, let it
            name_queue (bool): optional, if our name is in use by another
                service put ourselves in the D-Bus name queue, we will get
                name once the existing service relinquishes it

        Raises:
            BusError: if an error occurs during initialization

        """

        self.sdbus = sdbus.Service(
            name, bus, replace_existing, allow_replacement, name_queue
        )
        """Interface to sd-bus library"""

        self._add_to_loop(loop)

    def _add_to_loop(self, loop):

        bus_fd = self.sdbus.get_fd()
        if bus_fd <= 0:
            raise exceptions.BusError("Failed to read sd-bus file descriptor")

        if not loop:
            loop = asyncio.get_event_loop()

        loop.add_reader(bus_fd, self.sdbus.process)
