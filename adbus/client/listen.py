# == Copyright: 2017, CCX Technologies

import inspect

from .. import sdbus


class Listen:
    """Listens for a D-Bus Signal from another process.

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
        signature (str): optional, signature of the signal, if False the
            types of the coroutine arguments will be used to create the
            signature and the coroutine will be called with one argument
            per signal argument, if defined the coroutine will be called
            with a list of arguments, if None the coroutine will be called
            with a list of types determined at run-time
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
            signature=False,
    ):

        if signature is False:
            self.signature = ''
            sig = inspect.signature(coroutine)
            for param in sig.parameters.values():
                if param.annotation != inspect.Parameter.empty:
                    self.signature += sdbus.dbus_signature(param.annotation)
                else:
                    self.signature += sdbus.variant_signature()

        elif signature is None:
            self.signature = 'ANY'

        else:
            self.signature = signature

        try:
            self.sdbus = sdbus.Listen(
                    service.sdbus, address, path, interface, signal, coroutine,
                    args, self.signature.encode(), signature is False
            )
        except sdbus.SdbusError:
            # sometimes we'll get a EINTR (like one in a million trys), we want
            # to try again if we do
            self.sdbus = sdbus.Listen(
                    service.sdbus, address, path, interface, signal, coroutine,
                    args, self.signature.encode(), signature is False
            )
