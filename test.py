#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test scripts for async-dbus-python."""

from adbus.sd_bus import SdBusService

def test_service():
    """Test Service Creation."""

    def callback():
        print("ccccc")

    service = SdBusService("com.test")
    service.add_object("/com/test/xxx", callback)

    service.process()

if __name__ == "__main__":
    test_service()
