#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import typing
import asyncio
import random
import string
import time
from multiprocessing import Process

import adbus

service_name = 'adbus.test'
object_path = '/adbus/test/Tests1'
object_interface = 'adbus.test'


class Test(unittest.TestCase):
    """adbus method test cases."""

    @classmethod
    def rnd_str(cls, N=8):
        return ''.join(
                random.choice(string.ascii_uppercase + string.digits)
                for _ in range(N)
        )

    @classmethod
    def rnd_int(cls):
        return random.randint(-2000, 2000)

    @classmethod
    def run_test_wait(cls):
        import test_server
        test_server.Test.setUpClass()
        test = test_server.Test()
        test.test_method_wait()

    @classmethod
    def setUpClass(cls):
        cls.server = Process(target=cls.run_test_wait, name='run_test_wait')
        cls.server.start()
        time.sleep(3)

        cls.loop = asyncio.get_event_loop()
        cls.service = adbus.Service(bus='session')

    @classmethod
    def tearDownClass(cls):
        cls.server.terminate()

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

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    def test_call_complicated(self):

        async def call_basic():
            print("Calling...")

            class _Args:
                dbus_signature = "a{sv}"
                dbus_value = {"d": 10, "c": "a1234"}

            value = await adbus.client.call(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "ComplicatedArgs",
                    args=[_Args],
                    timeout_ms=6000
            )
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

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

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    def test_get_all(self):

        async def call_basic():
            value = await adbus.client.get_all(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
            )
            print(f"Returned {value}")

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    def test_set(self):

        async def call_basic():
            await adbus.client.set_(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "Property1",
                    "CRUD",
            )

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    def test_set_dict(self):

        class _Crud:
            dbus_signature = 'a{ss}'
            dbus_value = {"c": "43", "d": "test"}

        async def call_basic():
            x = {"a": "A", "b": "B"}
            await adbus.client.set_(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "ComplexType1",
                    {
                            "a": "A",
                            "b": "B"
                    },
            )
            value = await adbus.client.get(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "ComplexType1",
            )
            self.assertEqual(x, value)

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    def test_set_tuple(self):

        class _Crud:
            dbus_signature = 'a{ss}'
            dbus_value = {"c": "43", "d": "test"}

        async def call_basic():
            x = ('test', 'stuff', 100000)
            await adbus.client.set_(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "ComplexType2",
                    x,
            )
            value = await adbus.client.get(
                    self.service,
                    "adbus.test",
                    "/adbus/test/Tests1",
                    "adbus.test",
                    "ComplexType2",
            )
            for i, v in enumerate(value):
                self.assertEqual(x[i], v)

        self.loop.run_until_complete(asyncio.gather(call_basic(), ))

    @unittest.skip("long test used for development")
    def test_listen(self):

        async def test_cb(
                interface: str, changed: typing.Dict[str, typing.Any],
                invalidated: typing.List[str]
        ):
            print("Properties Changed")
            print((interface, changed, invalidated))

        self.listen = adbus.client.Listen(
                self.service, "adbus.test", "/adbus/test/Tests1",
                "org.freedesktop.DBus.Properties", "PropertiesChanged", test_cb
        )

        self.loop.run_until_complete(self.delay(30), )

    def test_proxy_props(self):
        proxy = adbus.client.Proxy(
                self.service, "adbus.test", "/adbus/test/Tests1", "adbus.test"
        )

        async def _test():
            await proxy.update()

            print(await proxy.test_method(100, "crud"))
            print(await proxy.property1.get())
            await proxy.property1.set(self.rnd_str())
            print(await proxy.property1())

            print(await proxy.property2())
            await proxy.property2(self.rnd_int())
            print(await proxy.property2())

        self.loop.run_until_complete(_test())

    def test_proxy_signal(self):
        proxy = adbus.client.Proxy(
                self.service, "adbus.test", "/adbus/test/Tests1", "adbus.test"
        )

        async def test_cb(count: int):
            print(f"Counter Changed {count}")

        async def _test():
            await proxy.update()

            proxy.signal_cnt(test_cb)
            await asyncio.sleep(9)

        self.loop.run_until_complete(_test())

    def test_proxy_interface(self):
        proxy = adbus.client.Proxy(
                self.service, "adbus.test", "/adbus/test/Tests1", "adbus.test"
        )

        async def _test():
            await proxy.update()

            print(await proxy.test_method(100, "crud"))

            proxy1 = proxy["org.freedesktop.DBus.Peer"]
            print(await proxy1.get_machine_id())

        self.loop.run_until_complete(_test())

    def test_proxy_nodes(self):
        proxy = adbus.client.Proxy(
                self.service, "adbus.test", "/adbus/test", "adbus.test"
        )

        async def _test():
            await proxy.update()

            proxy1 = await proxy("tests1")
            print(await proxy1.test_method(100, "crud"))

            async for p in proxy:
                print(await p.test_method(100, "crud"))

        self.loop.run_until_complete(_test())

    def test_proxy_multi_prop(self):
        proxy = adbus.client.Proxy(
                self.service, "adbus.test", "/adbus/test/Tests1", "adbus.test"
        )

        async def _test():
            await proxy.update()
            v1 = await proxy.property1()
            v2 = await proxy.property2()
            async with proxy as p:
                p.property1 = self.rnd_str()
                p.property2 = self.rnd_int()
            await self.delay(3)
            self.assertNotEqual(v1, await proxy.property1())
            self.assertNotEqual(v2, await proxy.property2())

        self.loop.run_until_complete(_test())


if __name__ == "__main__":
    unittest.main()
