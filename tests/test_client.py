#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import typing
import asyncio
import asyncio.subprocess

import adbus

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
            value = await adbus.client.call(
                self.service,
                "adbus.test",
                "/adbus/test/Tests1",
                "adbus.test",
                "SlowMethod",
                response_signature="",
                timeout_ms=6000
            )
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(
            call_basic(),
        ))

    def test_get(self):
        async def call_basic():
            value = await adbus.client.get(
                self.service,
                "adbus.test",
                "/adbus/test/Tests1",
                "adbus.test",
                "Property2",
            )
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(
            call_basic(),
        ))

    def test_get_all(self):
        async def call_basic():
            value = await adbus.client.get_all(
                self.service,
                "adbus.test",
                "/adbus/test/Tests1",
                "adbus.test",
            )
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(
            call_basic(),
        ))

    def test_set(self):
        async def call_basic():
            await set(
                self.service,
                "adbus.test",
                "/adbus/test/Tests1",
                "adbus.test",
                "Property1",
                "CRUD",
            )

        self.loop.run_until_complete(asyncio.gather(
            call_basic(),
        ))

    def test_listen(self):
        def test_cb(
            interface: str,
            changed: typing.Dict[str, typing.Any],
            invalidated: typing.List[str]
        ):
            print("Poperties Changed")
            print((interface, changed, invalidated))

        self.listen = adbus.client.Listen(
            self.service, "adbus.test", "/adbus/test/Tests1",
            "org.freedesktop.DBus.Properties", "PropertiesChanged", test_cb
        )

        self.loop.run_until_complete(
            self.delay(30),
        )


if __name__ == "__main__":
    unittest.main()
