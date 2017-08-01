#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import asyncio
import asyncio.subprocess
import typing
import time

import adbus

service_name = 'adbus.test'
object_path = '/adbus/test/Tests1'
object_interface = 'adbus.test'


class TestObject(adbus.server.Object):

    property1: str = adbus.server.Property('none')
    property2: int = adbus.server.Property(100, emits_change=False)
    property3: typing.List[int] = adbus.server.Property(
        [1, 2, 3]
    )

    signal1: (int, str) = adbus.server.Signal()
    signal2: int = adbus.server.Signal()
    signal_cnt: int = adbus.server.Signal()

    def __init__(self, service):
        super().__init__(
            service,
            object_path,
            object_interface,
            changed_coroutine=self.dummy_co
        )

    @adbus.server.method()
    def simple_method(self) -> int:
        return 1000

    @adbus.server.method()
    def test_method(self, r: int, gg: str) -> int:
        return r + len(gg)

    @adbus.server.method(name="DifferentName", depreciated=True)
    def test_method2(self, r: int, gg: str) -> int:
        return r + 10 * len(gg)

    @adbus.server.method()
    def slow_method(self) -> str:
        for _ in range(0, 5):
            time.sleep(1)
            print('-', end='', flush=True)
        return "Done"

    @adbus.server.method()
    def slow_error(self) -> str:
        for _ in range(0, 5):
            time.sleep(1)
            print('-', end='', flush=True)
        raise RuntimeError("Slow Test")

    @adbus.server.method()
    def error_method(self) -> str:
        raise RuntimeError("Test")

    @adbus.server.method()
    def var_method1(self, arg5: int, arg2: str, arg3, arg4, arg1: float):
        print(type(arg3))
        return str(arg3)

    async def dummy_co(self, names):
        if len(names) > 1:
            print(f"{names} where updated")
        else:
            print(f"{names[0]} was updated")


class Test(unittest.TestCase):
    """adbus method test cases."""

    @classmethod
    def setUpClass(cls):
        cls.loop = asyncio.get_event_loop()
        cls.service = adbus.Service(service_name, bus='session')
        cls.obj = TestObject(cls.service)

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

    async def call_method(
        self, method, arg_signature, args, return_signature, returns
    ):
        cmd = 'busctl --user -- call '
        cmd += f'{service_name} {object_path} {object_interface} {method}'
        cmd += f' "{arg_signature}"'
        for i in args:
            cmd += f' {i}'

        create = asyncio.create_subprocess_shell(
            cmd, stdout=asyncio.subprocess.PIPE
        )

        proc = await create

        # Read one line of output
        data = await proc.stdout.readline()
        line = data.decode('ascii').rstrip()

        self.assertEqual(line, f'{return_signature} {returns}')

        await proc.wait()

    def test_method_basic(self):
        self.loop.run_until_complete(
            self.call_method("TestMethod", "is", [-100, "doggie"], 'i', -94)
        )

    def test_method_rename(self):
        self.loop.run_until_complete(
            self.
            call_method("DifferentName", "is", [-100, "different"], 'i', -10)
        )

    def test_method_variants(self):
        self.loop.run_until_complete(
            self.call_method(
                "VarMethod1", "isvvd", [
                    -100, "different", 's', "test_string", 'i', 100, 12.5
                ], 'v s', '"test_string"'
            )
        )

    def test_method_wait(self):
        async def _ping():
            cnt = 0
            while True:
                print("Ping")
                self.obj.signal_cnt = cnt
                await asyncio.sleep(3)
                cnt += 1

        self.loop.run_until_complete(_ping())

    def test_property(self):
        self.obj.property1 = 'brown'

        async def set_props(obj):
            with obj as o:
                o.property1 = 'yellow'
                o.property2 = 42
                o.property3 = [6, 7, 10, 43, 102]

            await self.delay(3)

        self.loop.run_until_complete(set_props(self.obj))

    def test_signal(self):
        async def set_signal(obj):
            obj.signal1 = (1056, "Hello")
            obj.signal2 = -100
            await self.delay(3)

        self.loop.run_until_complete(set_signal(self.obj))


if __name__ == "__main__":
    unittest.main()
