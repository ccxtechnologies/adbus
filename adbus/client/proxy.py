# Copyright: 2017, CCX Technologies
"""D-Bus Proxy"""

import xml.etree.ElementTree as etree
import typing

from .. import sdbus
from .. import exceptions
from . import call
from . import get
from . import get_all
from . import set_
from . import Listen


class _Empty_Class:
    pass


class _DbusWrapper:
    def __init__(self, signature, value):
        self.dbus_signature = signature
        self.dbus_value = value


class Signal:
    def __init__(
            self, parent, service, address, path, interface, etree, timeout_ms
    ):
        self.parent = parent
        self.service = service
        self.address = address
        self.path = path
        self.interface = interface
        self.timeout_ms = timeout_ms
        self.signature = ''
        self.listens = {}

        for x in etree.iter():
            if x.tag == 'signal':
                self.name = x.attrib['name']
            if x.tag == 'arg':
                self.signature += x.attrib['type']

    def add(self, coroutine, signature=False):
        """Add a listening coroutine to this signal.

        Args:
            coroutine (coroutine): coroutine to schedule when signal received
            signature (str): optional, signature of the signal, if False the
                types of the coroutine arguments will be used to create the
                signature and the coroutine will be called with one argument
                per signal argument, if defined the coroutine will be called
                with a list of arguments, if None the coroutine will be called
                with a list of types determined at run-time
        """
        listen = Listen(
                self.service,
                self.address,
                self.path,
                self.interface,
                self.name,
                coroutine,
                signature=signature
        )

        if (
                (listen.signature != 'ANY')
                and (self.signature != listen.signature)
        ):
            raise exceptions.BusError(
                    f"Coroutine signature {listen.signature} doesn't "
                    f"match signal signature {self.signature}."
            )

        self.listens[coroutine.__name__] = listen

    def remove(self, coroutine):
        del self.listens[coroutine.__name__]

    def __call__(self, coroutine, remove=True):
        if remove and (coroutine.__name__ in self.listens):
            self.remove(coroutine)
        else:
            self.add(coroutine)


class Property:
    emits_changed_signal = 'true'
    cached_value = None

    def __init__(
            self, parent, service, address, path, interface, etree, timeout_ms
    ):
        self.parent = parent
        self.service = service
        self.address = address
        self.path = path
        self.interface = interface
        self.timeout_ms = timeout_ms
        self.name = etree.attrib['name']
        self.signature = etree.attrib['type']
        self.trackers = {}

        if etree.attrib['access'] == 'readwrite':
            self.readonly = False
        else:
            self.readonly = True

        for x in etree:
            if x.tag == 'annotation':
                if (
                        x.attrib['name'] ==
                        'org.freedesktop.DBus.Property.EmitsChangedSignal'
                ):
                    self.emits_changed_signal = x.attrib['value'].lower()

    async def get(self):
        if (
                (self.emits_changed_signal == 'false')
                or (self.cached_value is None)
        ):
            self.cached_value = await get(
                    self.service,
                    self.address,
                    self.path,
                    self.interface,
                    self.name,
                    timeout_ms=self.timeout_ms
            )

        return self.cached_value

    async def set(self, value):
        if self.emits_changed_signal == 'const':
            raise AttributeError(f"Can't set read-only property {self.name}")
        else:
            await set_(
                    self.service,
                    self.address,
                    self.path,
                    self.interface,
                    self.name,
                    sdbus.dbus_cast(self.signature, value),
                    timeout_ms=self.timeout_ms
            )

    def track(self, coroutine):
        self.trackers[coroutine.__name__] = coroutine

    def untrack(self, coroutine):
        del self.trackers[coroutine.__name__]

    async def __call__(self, value=None):
        if value is None:
            return await self.get()
        else:
            await self.set(value)
            return await self.get()


class Method:
    def __init__(
            self, parent, service, address, path, interface, etree, timeout_ms
    ):
        self.parent = parent
        self.service = service
        self.address = address
        self.path = path
        self.interface = interface
        self.timeout_ms = timeout_ms
        self.arg_signatures = []
        self.return_signature = ''

        for x in etree.iter():
            if x.tag == 'method':
                self.name = x.attrib['name']
            if x.tag == 'arg':
                if x.attrib['direction'] == 'out':
                    self.return_signature += x.attrib['type']
                elif x.attrib['direction'] == 'in':
                    self.arg_signatures.append(x.attrib['type'])

    async def __call__(self, *args):
        return await call(
                self.service,
                self.address,
                self.path,
                self.interface,
                self.name, [
                        _DbusWrapper(
                                self.arg_signatures[i],
                                sdbus.dbus_cast(self.arg_signatures[i], a)
                        ) for i, a in enumerate(args)
                ],
                self.return_signature,
                timeout_ms=self.timeout_ms
        )


class Interface:
    def __init__(
            self, parent, service, address, path, etree, camel_convert,
            timeout_ms, changed_coroutine
    ):
        self.parent = parent
        interface = etree.attrib['name']
        self.interface = interface
        self.methods = {}
        self.signals = {}
        self.properties = {}
        self.changed_coroutine = changed_coroutine
        self.camel_convert = camel_convert

        self.service = service
        self.address = address
        self.path = path
        self.interface = interface
        self.timeout_ms = timeout_ms

        def _add_snake_and_camel(d, n, v):
            d[n] = v
            if camel_convert:
                d[sdbus.camel_to_snake(n)] = v

        for m in etree.iter('method'):
            _add_snake_and_camel(
                    self.methods, m.attrib['name'],
                    Method(
                            self, service, address, path, interface, m,
                            timeout_ms
                    )
            )

        for p in etree.iter('property'):
            _add_snake_and_camel(
                    self.properties, p.attrib['name'],
                    Property(
                            self, service, address, path, interface, p,
                            timeout_ms
                    )
            )

        if self.properties:
            self.properties_changed_listen = Listen(
                    service,
                    address,
                    path,
                    "org.freedesktop.DBus.Properties",
                    "PropertiesChanged",
                    self.properties_changed,
                    args=(interface, ),
            )

        else:
            self.properties_changed_listen = None

        for s in etree.iter('signal'):
            _add_snake_and_camel(
                    self.signals, s.attrib['name'],
                    Signal(
                            self, service, address, path, interface, s,
                            timeout_ms
                    )
            )

    async def update_properties(self):
        if self.properties_changed_listen is not None:
            values = await get_all(
                    self.service, self.address, self.path, self.interface,
                    self.timeout_ms
            )
            for p, v in values.items():
                self.properties[p].cached_value = v

    async def properties_changed(
            self, interface: str, changed: typing.Dict[str, typing.Any],
            invalidated: typing.List[str]
    ):
        for p, v in changed.items():
            prop = self.properties[p]
            prop.cached_value = v
            for coroutine in prop.trackers.values():
                await coroutine(v)

        for p in invalidated:
            self.properties[p].cached_value = None

        if self.changed_coroutine:
            changed = list(changed.keys()) + invalidated
            if self.camel_convert:
                changed = [sdbus.camel_to_snake(x) for x in changed]
            await self.changed_coroutine(changed)

    def __getattr__(self, name):

        if name == 'properties':
            return self.properties

        if name == 'methods':
            return self.methods

        if name == 'signals':
            return self.signals

        try:
            return self.methods[name]
        except KeyError:
            pass

        try:
            return self.properties[name]
        except KeyError:
            pass

        try:
            return self.signals[name]
        except KeyError:
            pass

        raise AttributeError(
                f"'{self.interface}' interface has no attribute '{name}'"
        )

    def set_changed_coroutine(self, changed_coroutine):
        """Set the Interface's Changed Co-Routine."""
        self.changed_coroutine = changed_coroutine

    async def __aenter__(self):
        self._property_multi = _Empty_Class()
        return self._property_multi

    async def __aexit__(
            self, exception_type, exception_value, exception_traceback
    ):
        properties = _DbusWrapper(
                'a{sv}', {
                        sdbus.snake_to_camel(p) if self.camel_convert else p:
                        sdbus.dbus_cast(self.properties[p].signature, v)
                        for p, v in self._property_multi.__dict__.items()
                }
        )

        try:
            await self.parent["ccx.DBus.Properties"].methods["SetMulti"](
                    self.interface, properties
            )
        except KeyError:
            for p, v in properties.dbus_value.items():
                await self.properties[p].set(v)


class Proxy:
    """Creates a Python Object that maps to an Interface that already
    exists on the D-Bus.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the application to connect to
            on the D-Bus.
        path (str): path to create on the service
            ie. /com/awesome/Settings1
        interface (str): optional, default interface to access, if None will
            use address
        changed_coroutines: optional, coroutine dictionary of changed
            coroutines, the key is the name of the interface to attach
            to. The coroutine will be called with a single argument which is a
            list of property names.
        timeout_ms (int): optional, maximum time to wait for a response in
            milli-seconds
        camel_convert (bool): optional, D-Bus method and property
            names are typically defined in Camel Case, but Python
            methods and arguments are typically defined in Snake
            Case, if this is set the cases will be automatically
            converted between the two

    """

    _interface = None
    _introspect_xml = None

    def __init__(
            self,
            service,
            address,
            path,
            interface=None,
            changed_coroutines=None,
            timeout_ms=30000,
            camel_convert=True,
    ):
        self._node_i = 0
        self._interfaces = {}
        self._nodes = []

        self._service = service
        self._address = address
        self._path = path
        if not interface:
            self._interface = address
        else:
            self._interface = interface
        if changed_coroutines:
            self._changed_coroutines = changed_coroutines
        else:
            self._changed_coroutines = {}
        self._timeout_ms = timeout_ms
        self._camel_convert = camel_convert

    def __getattr__(self, name):
        if self._introspect_xml is None:
            raise RuntimeError("Must update proxy once before accessing.")
        return getattr(self._interfaces[self._interface], name)

    def __getitem__(self, interface):
        if self._introspect_xml is None:
            raise RuntimeError("Must update proxy once before accessing.")

        if interface not in self._interfaces:
            raise KeyError(f"Interface {interface} not in proxy")

        return self._interfaces[interface]

    async def __call__(self, node, changed_coroutines=None):
        if self._camel_convert:
            node = sdbus.snake_to_camel(node)

        if node not in self._nodes:
            raise AttributeError(f"Node {node} not in proxy")

        new = type(self)(
                self._service, self._address, f"{self._path}/{node}", None,
                changed_coroutines, self._timeout_ms, self._camel_convert
        )

        await new.update()
        return new

    async def __aenter__(self):
        return await self._interfaces[self._interface].__aenter__()

    async def __aexit__(
            self, exception_type, exception_value, exception_traceback
    ):
        return await self._interfaces[
                self._interface
        ].__aexit__(exception_type, exception_value, exception_traceback)

    def __aiter__(self):
        return self

    async def __anext__(self):
        i = self._node_i
        if i >= len(self._nodes):
            raise StopAsyncIteration
        proxy = await self(self._nodes[self._node_i])
        self._node_i += 1
        return proxy

    async def update(self, timeout_ms=None):
        """Use Introspection on remote server to update the proxy.
            **Must be run once before using the Proxy.**
        """
        timeout_ms = timeout_ms if timeout_ms is not None else self._timeout_ms

        self._introspect_xml = await call(
                self._service,
                self._address,
                self._path,
                'org.freedesktop.DBus.Introspectable',
                'Introspect',
                response_signature="s",
                timeout_ms=timeout_ms,
        )

        self._update_interfaces()
        for interface in self._interfaces.values():
            await interface.update_properties()

        return self

    def _update_interfaces(self):
        self._interfaces = {}

        root = etree.fromstring(self._introspect_xml)
        for e in root.iter('interface'):
            name = e.attrib['name']
            self._interfaces[name] = Interface(
                    self, self._service, self._address, self._path, e,
                    self._camel_convert, self._timeout_ms,
                    self._changed_coroutines.get(name, None)
            )

        for e in root.iter('node'):
            try:
                self._nodes.append(e.attrib['name'])
            except KeyError:
                pass
