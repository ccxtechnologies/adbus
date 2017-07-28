# == Copyright: 2017, CCX Technologies

from asyncio import wait_for
from .. import sdbus


async def call(
    service,
    address,
    path,
    interface,
    method,
    args=(),
    response_signature="",
    timeout_ms=30000
):

    call = sdbus.Call(
        service.sdbus,
        address.encode(),
        path.encode(),
        interface.encode(), method.encode(), args, response_signature.encode()
    )

    call.send(timeout_ms)
    await wait_for(call.wait_for_response(), timeout_ms/1000)
    response = call.get_response()

    if isinstance(response, Exception):
        raise response
    else:
        return response
