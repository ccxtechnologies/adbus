# == Copyright: 2017, CCX Technologies

from asyncio import Event
from .. import sdbus

async def call(service, address, path, interface,
        method, args=(), timeout_ms=30000):

    call = sdbus.Call(service.sdbus, address.encode(), path.encode(),
            interface.encode(), method.encode(), args)

    call.send(timeout_ms)
    await call.wait_for_response()
    return call.get_response()
