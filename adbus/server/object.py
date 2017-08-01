# Copyright: 2017, CCX Technologies
"""D-Bus Object"""

import asyncio

from .. import sdbus


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
        manager (bool): optional, if True add a device manager to this object,
            as defined by the D-Bus Spec from freedesktop.org
        changed_coroutine: optional, coroutine called with a list of changed
            properties, single argument is a list of property names, this is
            the internal equivalent to the emit changed D-Bus signal
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
        vtable=[],
        depreciated=False,
        hidden=False,
        manager=False,
        changed_coroutine=None,
        ccx=True,
    ):
        self._defer_properties = False
        self._deferred_properties = {}

        self.service = service
        self.path = path

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

        self.changed_coroutine = changed_coroutine

        self.ccx = ccx
        if self.ccx:
            self.service._add_ccx(self.path)

    def __dealloc__(self):
        if self.ccx:
            self.service._remove_ccx(self.path)

    def emit_property_changed(self, py_name, dbus_name):
        if self._defer_properties:
            self._deferred_properties[dbus_name.encode()] = py_name

        elif self.service.is_running():
            asyncio.ensure_future(
                self.sdbus.emit_properties_changed([dbus_name.encode()]),
                loop=self.service.get_loop()
            )

            if self.changed_coroutine:
                asyncio.ensure_future(
                    self.changed_coroutine([py_name]),
                    loop=self.service.get_loop()
                )

    def defer_signals(self, enable):
        if enable:
            self._defer_properties = True

        elif self._defer_properties:
            if not self.service.is_running():
                return

            self._defer_properties = False
            if self._deferred_properties:
                asyncio.ensure_future(
                    self.sdbus.emit_properties_changed(
                        list(self._deferred_properties.keys())
                    ),
                    loop=self.service.get_loop()
                )

                if self.changed_coroutine:
                    asyncio.ensure_future(
                        self.changed_coroutine(
                            list(self._deferred_properties.values())
                        ),
                        loop=self.service.get_loop()
                    )

            self._deferred_properties = {}

    def __enter__(self):
        self.defer_signals(True)
        return self

    def __exit__(self, exception_type, exception_value, exception_traceback):
        self.defer_signals(False)
