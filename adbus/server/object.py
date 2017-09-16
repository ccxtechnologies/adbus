# Copyright: 2017, CCX Technologies
"""D-Bus Object"""

import asyncio

from .. import sdbus
from .method import method

import typing


class Object:
    """Provides an interface between a D-Bus and a Python Object.

    Though this class can be used on its own it is intended to be inherited
    by another object which uses decorators to define methods, properties,
    and signals which are exposed on the D-Bus.

    This object must be added to a service, which provides the D-Bus interface.

    It also provides a Context Manager so that multiple properties can be set,
    or one property can be set multiple times, with a single D-Bus changed
    signal being sent for all property updates once the context is closed.

    Args:
        service (adbus.server.Service): service to connect to
        path (str): path to create on the service
            ie. /com/awesome/Settings
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
        manager (bool): optional, if True add a device manager to this object,
            as defined by the D-Bus Spec from freedesktop.org
        ccx: optional, add the additional ccx.DBus interface, which adds
            some useful methods like SetMulti

    Raises:
        BusError: if an error occurs during initialization

    """

    def __init__(
            self,
            service,
            path,
            interface,
            vtable=(),
            depreciated=False,
            hidden=False,
            manager=False,
            ccx=True,
    ):
        self._defer_properties = False
        self._deferred_property_signals = {}

        self.service = service
        self.path = path

        vtable = list(vtable)
        vtable += [
                v.vt(self) for v in type(self).__dict__.values()
                if hasattr(v, 'vt')
        ]

        self.sdbus = sdbus.Object(
                service.sdbus, path, interface, vtable, depreciated,
                hidden
        )
        """Interface to sd-bus library."""

        if manager:
            self.manager = sdbus.Manager(service.sdbus, path)

        try:
            self.ccx = _CCX(service, path) if ccx else None
        except sdbus.SdbusError as e:
            if e.errno == 17: # already exists
                self.ccx = None
            else:
                raise

    def emit_property_changed(self, dbus_name):
        if self._defer_properties:
            self._deferred_property_signals[dbus_name.encode()] = True

        elif self.service.is_running():
            asyncio.ensure_future(
                    self.sdbus.emit_properties_changed([dbus_name.encode()]),
                    loop=self.service.get_loop()
            )

    def defer_property_updates(self, enable):
        if enable:
            self._defer_properties = True

        elif self._defer_properties:
            if not self.service.is_running():
                return

            self._defer_properties = False
            if self._deferred_property_signals:
                asyncio.ensure_future(
                        self.sdbus.emit_properties_changed(
                                list(self._deferred_property_signals.keys())
                        ),
                        loop=self.service.get_loop()
                )

                self._deferred_property_signals = {}

    def __enter__(self):
        self.defer_property_updates(True)
        return self

    def __exit__(self, exception_type, exception_value, exception_traceback):
        self.defer_property_updates(False)


class _CCX(Object):
    """Provides additional useful methods, similar to org.freedesktop.DBus.

    NOTE: This isn't intended to be used directly, but will be automatically
    added to a path when the ccx property on an Object is true.

    Args:
        service (Service): service to add to
        path (str): path to connect to

    """

    def __init__(self, service, path):
        super().__init__(service, path, 'ccx.DBus', ccx=False)

    @method()
    def set_multi(
            self, interface: str, properties: typing.Dict[str, typing.Any]
    ) -> None:
        """Set multiple properties with a single call, similar to GetAll."""

        exceptions = ''
        with self as s:
            for name, value in properties.items():
                try:
                    setattr(s, name, value)
                except Exception as e:
                    exceptions += str(e) + "\n"

        if exceptions:
            raise ValueError(exceptions)
