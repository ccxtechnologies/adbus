#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies

"""test of low-level sd-bus snake and camel conversion utils"""

import unittest
import typing
from adbus.sdbus import object_signature

class Test(unittest.TestCase):
    """snake case test cases"""

    def test_objects(self):
        sig = object_signature('test')
        self.assertEqual(sig, "s")

        sig = object_signature({'test': 1, "brown": 45})
        self.assertEqual(sig, "a{si}")

        sig = object_signature([1,45,12])
        self.assertEqual(sig, "ai")

        def f(g :int, x: typing.List[int]):
            pass

        sig = object_signature(f.__annotations__['g'])
        self.assertEqual(sig, "i")

        sig = object_signature(f.__annotations__['x'])
        self.assertEqual(sig, "ai")

if __name__ == "__main__":
    unittest.main()
