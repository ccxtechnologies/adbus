#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test scripts for async-dbus-python."""

from adbus import _sdbus

def callback():
    print("Test Callback")

def test_service():
    """Test Service Creation."""

    s = _sdbus.Service(b"com.test")
    o = _sdbus.Object(s, b"/com/test/xxx", b"com.test.xxx",
            [_sdbus.Method(b"tester", callback)])

    s.process()

if __name__ == "__main__":
    test_service()
