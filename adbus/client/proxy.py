# Copyright: 2017, CCX Technologies
"""D-Bus Proxy"""

from .. import sdbus


class Proxy:

    introspect = None

    def __init__(
        self,
        service,
        address,
        path,
        interface=None,
        changed_callback=None,
    ):
        self.service = service
        self.address = address
        self.path = path
        if not interface:
            self.interface = self.address
        else:
            self.interface = interface
        self.changed_callback = changed_callback
