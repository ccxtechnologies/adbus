#!/usr/bin/env python3
# Copyright: 2017, CCX Technologies
"""Test of low-level sd-bus snake and camel conversion utilities"""

import unittest
from adbus.sdbus import snake_to_camel
from adbus.sdbus import camel_to_snake


class Test(unittest.TestCase):
    """Snake Case to Camel Case Converter test cases."""

    def test_snake_to_camel(self):
        c = snake_to_camel("test_one")
        self.assertEqual(c, "TestOne")

        c = snake_to_camel("test_two_three")
        self.assertEqual(c, "TestTwoThree")

        c = snake_to_camel("_test_two_three")
        self.assertEqual(c, "TestTwoThree")

        c = snake_to_camel("anotherTest")
        self.assertEqual(c, "AnotherTest")

    def test_camel_to_snake(self):
        c = camel_to_snake("testOne")
        self.assertEqual(c, "test_one")

        c = camel_to_snake("TestOne")
        self.assertEqual(c, "test_one")

        c = camel_to_snake("Test_One")
        self.assertEqual(c, "test__one")

        c = camel_to_snake("testOne")
        self.assertEqual(c, "test_one")

        c = camel_to_snake("TestOneTwoThree")
        self.assertEqual(c, "test_one_two_three")

        c = camel_to_snake("TTestOne")
        self.assertEqual(c, "t_test_one")


if __name__ == "__main__":
    unittest.main()
