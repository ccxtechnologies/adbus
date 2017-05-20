#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test scripts for async-dbus-python."""

from sdbus import Service

def test_service():
    """Test Service Creation."""

    service = Service("com.test")

    while(True):
        pass

if __name__ == "__main__":
    test_service()
