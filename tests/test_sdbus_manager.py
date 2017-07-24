#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
import asyncio.subprocess
from adbus.server.service import Service
from adbus.server.object import Object
from adbus.server.property import Property
from adbus.server.manager import Manager


class Test(unittest.TestCase):
    """sd-bus wrapper method test cases"""

    test_prop = 10

    @classmethod
    def setUpClass(cls):
        cls._loop = asyncio.get_event_loop()
        cls._service = Service("adbus.test", cls._loop)

    @classmethod
    def tearDownClass(cls):
        cls._loop.close()

    @staticmethod
    async def delay(loops=10):
        """Leave dbus up long enough for the test to run"""
        print('=' * loops)
        for _ in range(1, loops + 1):
            print('+', end='', flush=True)
            await asyncio.sleep(1)
        print('\n' + '=' * loops)

    def test_manager_basic(self):
        """test a basic object manager"""

        self.manager = Manager(self._service, "/adbus/test")

        prop_basic = Property(
            "Basic", self, 'test_prop', signature='i', emits_change=True)
        self.object = Object(self._service, "/adbus/test/methods",
                             "adbus.test", [prop_basic])

        self._loop.run_until_complete(self.delay(120))


if __name__ == "__main__":
    unittest.main()
