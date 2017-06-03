#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test scripts for async-dbus-python."""

from adbus import _sdbus

def callback(message):
    print("Test Callback")
    print(message.decode('utf-8', errors='ignore'))

def test_service():
    """Test Service Creation."""

    s = _sdbus.Service(b"com.test")
    m = [_sdbus.Method(b"Crud", callback, arg_types=b's')]
    o = _sdbus.Object(s, b"/com/test/crud", b"com.test.crud", m)

    s.process()

if __name__ == "__main__":
    test_service()
