# Copyright: 2017, Charles Eidsness

"""D-Bus Object"""

from .. import sdbus

class Manager:
    """D-Bus Object"""

    def __init__(self, service, path):
        self.sdbus = sdbus.Manager(service.sdbus, path)
