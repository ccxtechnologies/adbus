# Copyright: 2017, CCX Technologies
"""D-Bus Object"""

from .. import sdbus


class Object:
    """Provides an interface between a D-Bus and a Python Object.

    Though this class can be used on its own it is intended to be inherited
    by another object which uses decorators to define methods, properties,
    and signals which are exposed on the D-Bus.

    This object must be added to a service, which provides the D-Bus interface.

    Args:
        service (Service): service to connect to
        path (str): path to create on the service
            ie. /com/awesome/Settings1
        interface (str): interface label to use for all of this
            objects methods and properties, ie. com.awesome.settings
        vtable (list): optional, list of signals, methods, and
            properties that will be added to the D-Bus Object,
            this list is in addition to the methods, properties, and
            signals which are added to this object using the provided
            decorators and descriptors
        depreciated (bool): optional, if true object is labelled
            as depreciated in the introspect XML data
        hidden (bool): optional, if true object won't be added
            to the introspect XML data
        manager (bool): add a device manager to this object, as
            defined by the D-Bus Spec from freedesktop.org

    Raises:
        BusError: if an error occurs during initialization

    """

    def __init__(
        self,
        service,
        path,
        interface,
        vtable=[],
        depreciated=False,
        hidden=False,
        manager=False
    ):
        self._defer_properties = False
        self._deferred_properties = {}

        self.vtable = [x.vt() for x in vtable]
        """List of all D-Bus Methods, Properties, and Signals."""

        self.vtable += [
            v.vt(self)
            for v in type(self).__dict__.values() if hasattr(v, 'vt')
        ]

        self.sdbus = sdbus.Object(
            service.sdbus, path, interface, self.vtable, depreciated, hidden
        )
        """Interface to sd-bus library."""

        if manager:
            self.manager = sdbus.Manager(service.sdbus, path)

    def emit_property_changed(self, name):
        if self._defer_properties:
            self._deferred_properties[name.encode()] = None
        elif self.sdbus.is_connected():
            self.sdbus.emit_properties_changed([name.encode()])

    def defer_signals(self, enable):
        if enable:
            self._defer_properties = True

        elif self._defer_properties:
            self._defer_properties = False

            if self._deferred_properties:
                self.sdbus.emit_properties_changed(
                    list(self._deferred_properties.keys())
                )
                self._deferred_properties = {}

    def __enter__(self):
        self.defer_signals(True)
        return self

    def __exit__(self, exception_type, exception_value, exception_traceback):
        self.defer_signals(False)

