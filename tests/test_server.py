#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import asyncio
import asyncio.subprocess
import typing
import time
import sys
from multiprocessing import current_process

import adbus

service_name = 'adbus.test'
object_path = '/adbus/test/Tests1'
object_interface = 'adbus.test'


class TestDataType:
    dbus_signature = 's'

    def __init__(self, value):
        if int(value) > 12:
            raise ValueError
        self.value = int(value) + 100
        self.dbus_value = str(self.value)


class _TestObect:
    dbus_signature = 'o'
    dbus_value = '/this/is/nothing'


class TestObject(adbus.server.Object):

    property1: str = adbus.server.Property('propertystring')
    property2: int = adbus.server.Property(100, emits_change=False)
    property3: typing.List[int] = adbus.server.Property([1, 2, 3])
    datatype: TestDataType = adbus.server.Property(TestDataType(6))

    complex_type1: typing.Dict[str, str] = adbus.server.Property(
            {
                    "a": "10",
                    "b": "hello"
            }
    )

    complex_type2: typing.Tuple[str, str,
                                int] = adbus.server.Property(("a", "b", 10))

    signal1: (int, str) = adbus.server.Signal()
    signal2: int = adbus.server.Signal()
    signal_cnt: int = adbus.server.Signal()

    def __init__(self, service):
        super().__init__(
                service,
                object_path,
                object_interface,
        )

    @adbus.server.method()
    def str_list_method(self) -> typing.List[str]:
        return ['thisisthefirst', 'two', 'three']

    @adbus.server.method()
    def simple_method(self) -> int:
        return 1000

    @adbus.server.method()
    def test_method(self, r: int, gg: str) -> int:
        return r + len(gg)

    @adbus.server.method(name="DifferentName", deprecated=True)
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

    @adbus.server.method()
    def add_object(self) -> None:
        self.test = adbus.server.Object(
                self.service,
                object_path + '/Test',
                object_interface,
                ccx=True
        )

    @adbus.server.method()
    def del_object(self) -> None:
        del self.test

    @adbus.server.method()
    def complicated_args(
            self, properties: typing.Dict[str, typing.Any]
    ) -> _TestObect:
        print(properties)
        return "/this/is/nothing"


class Test(unittest.TestCase):
    """adbus method test cases."""

    @classmethod
    def setUpClass(cls):
        cls.loop = asyncio.get_event_loop()
        cls.service = adbus.Service(
                service_name,
                bus='session',
                replace_existing=True,
                allow_replacement=True
        )
        cls.obj = TestObject(cls.service)

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
                self.call_method(
                        "TestMethod", "xs", [-100, "doggie"], 'x', -94
                )
        )

    def test_str_list(self):
        self.loop.run_until_complete(
                self.call_method(
                        "StrListMethod", "", [''], 'as',
                        '3 "thisisthefirst" "two" "three"'
                )
        )

    def test_method_rename(self):
        self.loop.run_until_complete(
                self.call_method(
                        "DifferentName", "xs", [-100, "different"], 'x', -10
                )
        )

    def test_method_variants(self):
        self.loop.run_until_complete(
                self.call_method(
                        "VarMethod1", "xsvvd", [
                                -100, "different", 's', "test_string", 'x',
                                100, 12.5
                        ], 'v s', '"test_string"'
                )
        )

    @unittest.skipIf(
            "tests.test_server.Test.test_method_wait" not in sys.argv and \
            current_process().name != "run_test_wait",
            "long test used for development"
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
