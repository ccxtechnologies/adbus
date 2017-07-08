# Copyright: 2017, CCX Technologies

"""D-Bus Object"""

from .. import sdbus
from .. import exceptions

class Object:
    """Provides an interface between a D-Bus and a Python Object.

    Though this class can be used on its own it is intended to be inherited
    by another object which uses decorators to define methods, properties,
    and signals that are exposed on the D-Bus.

    The object must be added to a service, which provides the D-Bus interface.
    It must be running in an asyncio loop to process requests.
    """

    def __init__(self, service, path, interface, vtable=[],
            deprectiated=False, hidden=False, manager=False):
        """D-Bus Object Initilization.

        Args:
            service (Service): service to connect to
            path (str): path to create on the service,
                ie. /com/awesome/Settings1
            interface (str): interface label to use for all of this
                objects methods and properties, ie. com.awesome.settings
            vtable (list): optional, list of signals, methods, and
                properties that will be added to the decorator defined items
            deprectiated (bool): optional, if true object is labelled
                as deprectiated in the introspect XML data
            hidden (bool): optional, if true object won't be added
                to the introspect XML data
            manager (bool): add a device manager to this object, as
                defined by the D-Bus Spec from freedesktop.org

        Raises:
            BusError: if an error occurs during initialization

        """

        #TODO: Create the vtable from the decorated items

        try:
            self.sdbus = sdbus.Object(service.sdbus, path, interface,
                [v.sdbus for v in vtable], deprectiated, hidden)
            """Interface to sd-bus library"""
        except sdbus.BusError as exc:
            raise exceptions.BusError(str(exc)) from exc

        if manager:
            self.manager = sdbus.Manager(service.sdbus, path)

    def emit_properties_changed(self, properties):
        self.sdbus.emit_properties_changed([p.sdbus for p in properties])

