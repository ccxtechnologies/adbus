# Copyright: 2017, CCX Technologies
"""D-Bus Proxy"""

import xml.etree.ElementTree as etree
import typing
import copy

from .. import sdbus
from . import call
from . import get
from . import get_all
from . import set
from . import Listen


class Signal:
    def __init__(self, service, address, path, interface, etree, timeout_ms):
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

    def add(self, coroutine):
        self.listens[coroutine.__name__] = Listen(
            self.service,
            self.address,
            self.path,
            self.interface,
            self.name,
            coroutine,
            signature=self.signature
        )

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

    def __init__(self, service, address, path, interface, etree, timeout_ms):
        self.service = service
        self.address = address
        self.path = path
        self.interface = interface
        self.timeout_ms = timeout_ms
        self.name = etree.attrib['name']
        self.signature = etree.attrib['type']
        if etree.attrib['access'] == 'readwrite':
            self.readonly = False
        else:
            self.readonly = True

        for x in etree:
            if x.tag == 'annotation':
                if (x.attrib['name'] ==
                        'org.freedesktop.DBus.Property.EmitsChangedSignal'):
                    self.emits_changed_signal = x.attrib['value'].lower()

    async def get(self):
        if ((self.emits_changed_signal == 'false') or
                (self.cached_value is None)):
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
            await set(
                self.service,
                self.address,
                self.path,
                self.interface,
                self.name,
                value,
                timeout_ms=self.timeout_ms
            )

    async def __call__(self, value=None):
        if value is None:
            return await self.get()
        else:
            await self.set(value)
            return await self.get()


class Method:
    def __init__(self, service, address, path, interface, etree, timeout_ms):
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
                    self.return_signature = x.attrib['type']
                elif x.attrib['direction'] == 'in':
                    self.arg_signatures.append(x.attrib['type'])

    async def __call__(self, *args):
        return await call(
            self.service,
            self.address,
            self.path,
            self.interface,
            self.name,
            args,
            self.return_signature,
            timeout_ms=self.timeout_ms
        )


class Interface:
    def __init__(
        self, service, address, path, etree, camel_convert, timeout_ms,
        changed_coroutine
    ):
        interface = etree.attrib['name']
        self.methods = {}
        self.signals = {}
        self.properties = {}
        self.changed_coroutine = changed_coroutine

        def _add_snake_and_camel(d, n, v):
            d[n] = v
            if camel_convert:
                d[sdbus.camel_to_snake(n)] = v

        for m in etree.iter('method'):
            _add_snake_and_camel(
                self.methods, m.attrib['name'],
                Method(service, address, path, interface, m, timeout_ms)
            )

        for p in etree.iter('property'):
            _add_snake_and_camel(
                self.properties, p.attrib['name'],
                Property(service, address, path, interface, p, timeout_ms)
            )

        if self.properties:
            self.properties_changed_listen = Listen(
                service, address, path, "org.freedesktop.DBus.Properties",
                "PropertiesChanged", self.properties_changed
            )

            self.get_all = get_all(
                service, address, path, interface, timeout_ms
            )
        else:
            self.get_all = None

        for s in etree.iter('signal'):
            _add_snake_and_camel(
                self.signals, s.attrib['name'],
                Signal(service, address, path, interface, s, timeout_ms)
            )

    async def update_properties(self):
        if self.get_all:
            values = await self.get_all
            for p, v in values.items():
                self.properties[p].cached_value = v

    async def properties_changed(
        self,
        interface: str,
        changed: typing.Dict[str, typing.Any],
        invalidated: typing.List[str]
    ):
        for p, v in changed.items():
            self.properties[p].cached_value = v
        for p in invalidated:
            self.properties[p].cached_value = None

        if self.changed_coroutine:
            changed = list(changed.keys()) + invalidated
            if self.camel_convert:
                changed = [sdbus.camel_to_snake(x) for x in changed]
            self.changed_coroutine(changed)


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
        changed_coroutine: optional, coroutine called with a list of changed
            properties, single argument is a list of property names, this is
            the internal equivalent to the emit changed D-Bus signal
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
        changed_coroutine=None,
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
        self._changed_coroutine = changed_coroutine
        self._timeout_ms = timeout_ms
        self._camel_convert = camel_convert

    def __getattr__(self, name):
        if self._introspect_xml is None:
            raise RuntimeError("Must update proxy once before accessing.")

        if name == 'properties':
            return self._interfaces[self._interface].properties

        if name == 'methods':
            return self._interfaces[self._interface].methods

        if name == 'signals':
            return self._interfaces[self._interface].signals

        try:
            return self._interfaces[self._interface].methods[name]
        except KeyError:
            pass

        try:
            return self._interfaces[self._interface].properties[name]
        except KeyError:
            pass

        try:
            return self._interfaces[self._interface].signals[name]
        except KeyError:
            pass

        raise AttributeError(
            f"'{type(self)}' interface has no attribute '{name}'"
        )

    def __getitem__(self, interface):
        if interface not in self._interfaces:
            raise KeyError(f"Interface {interface} not in proxy")

        new = copy.copy(self)
        new._interface = interface
        return new

    def __copy__(self):
        new = type(self)(
            self._service, self._address, self._path, self._interface,
            self._changed_coroutine, self._timeout_ms, self._camel_convert
        )

        new._interface = self._interface
        new._interfaces = self._interfaces
        new._introspect_xml = self._introspect_xml

        return new

    async def __call__(self, node, changed_coroutine=None):
        if self._camel_convert:
            node = sdbus.snake_to_camel(node)

        if node not in self._nodes:
            raise AttributeError(f"Node {node} not in proxy")

        new = type(self)(
            self._service, self._address, f"{self._path}/{node}", None,
            changed_coroutine, self._timeout_ms, self._camel_convert
        )

        await new.update()
        return new

    async def __aenter__(self):
        class _AsyncProps:
            dbus_signature = 'a{sv}'

            def __init__(self, camel_convert):
                self._camel_convert = camel_convert

            async def __await__(self):
                pass

            @property
            def dbus_value(self):
                if self._camel_convert:
                    return {
                        sdbus.snake_to_camel(p): v
                        for p, v in self.__dict__.items()
                        if p != "_camel_convert"
                    }
                else:
                    return {
                        p: v
                        for p, v in self.__dict__.items()
                        if p != "_camel_convert"
                    }

        self._property_multi = _AsyncProps(self._camel_convert)
        return self._property_multi

    async def __aexit__(
        self, exception_type, exception_value, exception_traceback
    ):
        try:
            await self._interfaces["ccx.DBus"].methods["SetMulti"](
                self._interface, self._property_multi
            )
        except KeyError:
            for p, v in self._property_multi.dbus_value.items():
                await self._interfaces[self._interface].properties[p].set(v)

    async def __aiter__(self):
        return self

    async def __anext__(self):
        i = self._node_i
        if i >= len(self._nodes):
            raise StopAsyncIteration
        proxy = await self(self._nodes[self._node_i])
        self._node_i += 1
        return proxy

    async def update(self):
        """Use Introspection on remote server to update the proxy.
            **Must be run once before using the Proxy.**
        """
        self._introspect_xml = await call(
            self._service,
            self._address,
            self._path,
            'org.freedesktop.DBus.Introspectable',
            'Introspect',
            response_signature="s"
        )

        self._update_interfaces()
        for interface in self._interfaces.values():
            await interface.update_properties()

    def _update_interfaces(self):
        self._interfaces = {}

        root = etree.fromstring(self._introspect_xml)
        for e in root.iter('interface'):
            self._interfaces[e.attrib['name']] = Interface(
                self._service, self._address, self._path, e,
                self._camel_convert, self._timeout_ms, self._changed_coroutine
            )

        for e in root.iter('node'):
            try:
                self._nodes.append(e.attrib['name'])
            except KeyError:
                pass
