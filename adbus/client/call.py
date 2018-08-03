# == Copyright: 2017, CCX Technologies

from .. import sdbus


async def call(
        service,
        address,
        path,
        interface,
        method,
        args=(),
        response_signature=None,
        timeout_ms=30000
):
    """Calls a D-Bus Method in another process.

    This is a co-routine, so must be await-ed from within a asyncio mainloop.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the D-Bus Service to call
        path (str): path of method to call, ie. /com/awesome/Settings1
        interface (str): interface label to call, ie. com.awesome.settings
        method (str): name of the method to call, ie. TestMethod
        args (list or tuple): optional, list of arguments to pass to the method
        response_signature (str): optional, D-Bus Signature of the expected
            response, if None the signature will be created at run-time,
            specifying it here will speed up the message post-processing
        timeout_ms (int): maximum time to wait for a response in milli-seconds

    """

    _response_signature = (
            b"Any"
            if response_signature is None else response_signature.encode()
    )

    call = sdbus.Call(
            service.sdbus, address.encode(), path.encode(), interface.encode(),
            method.encode(), args, _response_signature
    )

    call.send(timeout_ms)
    await call.event.wait()

    if isinstance(call.response, Exception):
        raise call.response
    else:
        return call.response
