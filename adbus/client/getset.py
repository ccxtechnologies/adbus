# == Copyright: 2017, CCX Technologies

from asyncio import wait_for
from .. import sdbus


async def get(service, address, path, interface, name, timeout_ms=30000):

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"Get",
        (interface, name), b"v"
    )

    call.send(timeout_ms)
    await wait_for(call.wait_for_response(), timeout_ms / 1000)
    response = call.get_response()

    if isinstance(response, Exception):
        raise response
    else:
        return response


async def get_all(service, address, path, interface, timeout_ms=30000):

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"GetAll",
        (interface, ), b"a{sv}"
    )

    call.send(timeout_ms)
    await wait_for(call.wait_for_response(), timeout_ms / 1000)
    response = call.get_response()

    if isinstance(response, Exception):
        raise response
    else:
        return response

class _variant_wrapper:

    def __init__(self, value):
        self.dbus_value = value
        self.dbus_signature = "v"

async def set(service, address, path, interface, name, value, timeout_ms=30000):

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"Set",
        (interface, name, _variant_wrapper(value))
    )

    call.send(timeout_ms)
    await wait_for(call.wait_for_response(), timeout_ms / 1000)
    response = call.get_response()

    if isinstance(response, Exception):
        raise response
