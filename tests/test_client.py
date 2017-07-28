#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import asyncio
import asyncio.subprocess
import typing
import time

import adbus
from adbus.client.call import call

service_name = 'adbus.test'
object_path = '/adbus/test/Tests1'
object_interface = 'adbus.test'

class Test(unittest.TestCase):
    """adbus method test cases."""

    @classmethod
    def setUpClass(cls):
        cls.loop = asyncio.get_event_loop()
        cls.service = adbus.Service(bus='session')

    @classmethod
    def tearDownClass(cls):
        cls.loop.close()

    @staticmethod
    async def delay(loops=10):
        print('=' * loops)
        for _ in range(1, loops + 1):
            print('+', end='', flush=True)
            await asyncio.sleep(1)
        print('\n' + '=' * loops)

    def test_call_basic(self):

        async def call_basic():
            print("Calling...")
            value = await call(self.service, "adbus.test", "/adbus/test/Tests1",
                    "adbus.test", "SlowMethod")
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(
                call_basic(),
                self.delay(10),
                )
        )

if __name__ == "__main__":
    unittest.main()
