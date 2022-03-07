#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test of low-level signature creator."""

import unittest
import typing
from adbus.sdbus import dbus_signature


class Test(unittest.TestCase):
    """D-Bus Signature Creator test cases."""

    def test_objects(self):
        sig = dbus_signature('test')
        self.assertEqual(sig, "s")

        sig = dbus_signature(1)
        self.assertEqual(sig, "i")

        sig = dbus_signature(3000000000)
        self.assertEqual(sig, "i")

        sig = dbus_signature({'test': 1, "brown": 45})
        self.assertEqual(sig, "a{si}")

        sig = dbus_signature([1, 45, 12])
        self.assertEqual(sig, "ai")

        def f(g: int, x: typing.List[int]):
            pass

        sig = dbus_signature(f.__annotations__['g'])
        self.assertEqual(sig, "i")

        sig = dbus_signature(f.__annotations__['x'])
        self.assertEqual(sig, "ai")

        with self.assertRaises(TypeError):
            dbus_signature(Test)


if __name__ == "__main__":
    unittest.main()
