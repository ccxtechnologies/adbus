# == Copyright: 2017, CCX Technologies

from asyncio import wait_for
from .. import sdbus
from .. import datatypes


async def get(service, address, path, interface, name, timeout_ms=30000):
    """Gets a D-Bus Property from another process.

    This is a co-routine, so must be await-ed from within a asyncio mainloop.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the D-Bus Service to call
        path (str): path of method to call, ie. /com/awesome/Settings1
        interface (str): interface label to call, ie. com.awesome.settings
        name (str): name of the name to get, ie. TestProperty
        timeout_ms (int): maximum time to wait for a response in milli-seconds

    Returns:
        Value of the name.
    """

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"Get",
        (interface, name), b"v"
    )

    call.send(timeout_ms)
    await call.event.wait()

    if isinstance(call.response, Exception):
        raise call.response
    else:
        return call.response


async def get_all(service, address, path, interface, timeout_ms=30000):
    """Gets a All D-Bus Properties from another process.

    This is a co-routine, so must be await-ed from within a asyncio mainloop.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the D-Bus Service to call
        path (str): path of method to call, ie. /com/awesome/Settings1
        interface (str): interface label to call, ie. com.awesome.settings
        timeout_ms (int): maximum time to wait for a response in milli-seconds

    Returns:
        A dictionary, keys are the name names and values are the name
        values.
    """

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"GetAll",
        (interface, ), b"a{sv}"
    )

    call.send(timeout_ms)
    await call.event.wait()

    if isinstance(call.response, Exception):
        raise call.response
    else:
        return call.response


async def set_(
    service, address, path, interface, name, value, timeout_ms=30000
):
    """Sets a D-Bus Property in another process.

    This is a co-routine, so must be await-ed from within a asyncio mainloop.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the D-Bus Service to call
        path (str): path of method to call, ie. /com/awesome/Settings1
        interface (str): interface label to call, ie. com.awesome.settings
        name (str): name of the name to get, ie. TestProperty
        value (object): value to set the name to, must be compatible
            with the defined D-Bus Property type
        timeout_ms (int): maximum time to wait for a response in milli-seconds
    """

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(), b"org.freedesktop.DBus.Properties", b"Set",
        (interface, name, datatypes.VariantWrapper(value))
    )

    call.send(timeout_ms)
    await call.event.wait()

    if isinstance(call.response, Exception):
        raise call.response
