# == Copyright: 2017, CCX Technologies


class VariantWrapper:
    """Creates a D-Bus Variant from any value.
            For sending to D-Bus Interfaces.
    """
    dbus_signature = "v"

    def __init__(self, value):
        self.dbus_value = value
        self.value = value
