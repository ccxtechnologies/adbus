#!/usr/bin/env python3

# Copyright: 2017, CCX Technologies
"""Test the method wrapper and decorators."""

import unittest
import asyncio
import asyncio.subprocess

import adbus.server

service_name = 'adbus.test'
object_path = '/adbus/test/Methods'
object_interface = 'adbus.test'


class TestObject(adbus.server.Object):
    def __init__(self, service):
        super().__init__(service, object_path, object_interface)

    @adbus.server.method()
    def test_method(self, r: int, gg: str) -> int:
        return r + len(gg)


class Test(unittest.TestCase):
    """adbus method test cases."""

    @classmethod
    def setUpClass(cls):
        cls.loop = asyncio.get_event_loop()
        cls.service = adbus.server.Service(service_name, bus='session')

    @classmethod
    def tearDownClass(cls):
        pass
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

        TestObject(self.service)

        self.loop.run_until_complete(
            self.call_method(
                "TestMethod", "is", [-100, "doggie"], 'i', -94
            )
        )

if __name__ == "__main__":
    unittest.main()
