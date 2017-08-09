# == Copyright: 2017, CCX Technologies
"""A collection of more complex data-types that can be used on the D-Bus."""

import ipaddress


class VariantWrapper:
    """Creates a D-Bus Variant from any value.
            For sending to D-Bus Interfaces.
    """
    dbus_signature = "v"

    def __init__(self, value):
        self.dbus_value = value
        self.value = value


class IPv4Address(ipaddress.IPv4Address):
    """Super class of ipaddress.IPv4Address for use over D-Bus via strings."""

    dbus_signature = "s"

    @property
    def dbus_value(self):
        return str(self)


class IPv4Network(ipaddress.IPv4Network):
    """Super class of ipaddress.IPv4Network for use over D-Bus via strings."""

    dbus_signature = "s"

    def __init__(self, value):
        super().__init__(value, strict=False)

    @property
    def dbus_value(self):
        return str(self)
