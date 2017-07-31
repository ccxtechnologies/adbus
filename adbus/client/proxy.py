# Copyright: 2017, CCX Technologies
"""D-Bus Proxy"""

import xml.etree.ElementTree as etree

from .. import sdbus
from . import call


class _Signal:
    def __init__(self, etree):
        self.arg_signatures = []
        print((etree.tag, etree.attrib))


class _Property:
    def __init__(self, etree):
        self.name = etree.attrib['name']
        self.signature = etree.attrib['type']
        if etree.attrib['access'] == 'readwrite':
            self.readonly = False
        else:
            self.readonly = True


class _Method:
    def __init__(self, etree):
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


class _Interface:
    def __init__(self, etree):
        self.methods = {}
        self.signals = {}
        self.properties = {}

        for m in etree.iter('method'):
            self.methods[m.attrib['name']] = _Method(m)

        for p in etree.iter('property'):
            self.properties[p.attrib['name']] = _Property(p)

        for s in etree.iter('signal'):
            self.properties[s.attrib['name']] = _Signal(s)


class Proxy:

    interfaces = {}
    introspect_xml = None

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

        self.service = service
        self.address = address
        self.path = path
        if not interface:
            self.interface = self.address
        else:
            self.interface = interface
        self.changed_coroutine = changed_coroutine
        self.timeout_ms = timeout_ms
        self.camel_convert = camel_convert

    async def introspect(self):
        self.introspect_xml = await call(
            self.service,
            self.address,
            self.path,
            'org.freedesktop.DBus.Introspectable',
            'Introspect',
            response_signature="s"
        )

        self._update_interfaces()

    def _update_interfaces(self):
        self.interfaces = {}

        root = etree.fromstring(self.introspect_xml)
        for e in root.iter('interface'):
            self.interfaces[e.attrib['name']] = _Interface(e)
