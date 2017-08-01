# == Copyright: 2017, CCX Technologies

import inspect

from .. import sdbus
from .. import exceptions


class Listen:
    """Calls a D-Bus Method in another process.

    This is a co-routine, so must be await-ed from within a asyncio mainloop.

    Args:
        service (adbus.server.Service): service to connect to
        address (str): address (name) of the D-Bus Service to call
        path (str): path of method to call, ie. /com/awesome/Settings1
        interface (str): interface label to call, ie. com.awesome.settings
        signal (str): name of the signal to listen to, ie. TestSignal
        coroutine (coroutine): coroutine to schedule when signal is received
        args (list or tuple): optional, list of argument values to match,
            the argument must be a string, useful for listening to property
            changes
        signature (str): optional, signature of the signal, used to verify
            that the coroutine is correct, if None disables check
    """

    def __init__(
        self,
        service,
        address,
        path,
        interface,
        signal,
        coroutine,
        args=(),
        signature=None,
    ):

        self.signature = ''
        sig = inspect.signature(coroutine)
        for param in sig.parameters.values():
            if param.annotation != inspect.Parameter.empty:
                self.signature += sdbus.dbus_signature(param.annotation)
            else:
                self.signature += sdbus.variant_signature()

        if (signature is not None) and (signature != self.signature):
            raise exceptions.BusError(
                    f"Coroutine signature {self.signature} doesn't "
                    f"match signal signature {signature}.")

        self.sdbus = sdbus.Listen(
            service.sdbus, address, path, interface, signal, coroutine, args,
            self.signature
        )
