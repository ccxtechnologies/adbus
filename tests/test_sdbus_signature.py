#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness

"""test of low-level sd-bus snake and camel conversion utils"""

import unittest
from adbus.sdbus import object_signature

class Test(unittest.TestCase):
    """snake case test cases"""

    def test_objects(self):
        s = object_signature('test')
        self.assertEqual(c, "s")

if __name__ == "__main__":
    unittest.main()
