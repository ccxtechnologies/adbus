# Copyright: 2017, CCX Technologies
"""D-Bus Object"""

import typing

from . import Object
from . import method


class _CCXInterface(Object):
    """Provides additional useful methods, similar to org.freedesktop.DBus.

    NOTE: This isn't intended to be used directly, but will be automatically
    added to a path when the ccx property on an Object is true.

    Args:
        service (Service): service to add to
        path (str): path to connect to

    """

    refernce_count = 1

    def __init__(self, service, path):
        super().__init__(service, path, 'ccx.DBus', ccx=False)

    @method()
    def set_multi(
        self, interface: str, properties: typing.Dict[str, typing.Any]
    ) -> None:
        """Set multiple properties with a single call, similar to GetAll."""

        with self as s:
            for name, value in properties.items():
                setattr(s, name, value)
