#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness

"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
import asyncio.subprocess
from adbus.server.service import Service
from adbus.server.object import Object
from adbus.server.method import Method

class Test(unittest.TestCase):
    """sd-bus wrapper method test cases"""

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
        print('='*loops)
        for _ in range(1, loops+1):
            print('+', end='', flush=True)
            await asyncio.sleep(1)
        print('\n' + '='*loops)

    async def call_method(self, method, arg_signature, args, return_signature, returns):
        """Call a method via d-bus"""

        service = 'adbus.test'
        path = '/adbus/test/methods'
        interface = 'adbus.test'

        cmd = f'busctl --user -- call {service} {path} {interface} {method} "{arg_signature}"'
        for i in args:
            cmd += f' {i}'

        create = asyncio.create_subprocess_shell(cmd,
                stdout=asyncio.subprocess.PIPE)

        proc = await create

        # Read one line of output
        data = await proc.stdout.readline()
        line = data.decode('ascii').rstrip()

        self.assertEqual(line, f'{return_signature} {returns}')

        # Wait for the subprocess exit
        await proc.wait()

    def test_method_basic(self):
        """test a basic method"""

        def _callback(arg1, arg2, arg3):
            return f"callback {arg1}, {arg2}, {arg3}"

        self.obj = Object(self._service, "/adbus/test/methods", "adbus.test",
                [Method("BasicMethod", _callback, arg_signature='ius',
                    return_signature='s')])

        self._loop.run_until_complete(self.call_method("BasicMethod",
            "ius", [-100, 100, "doggie"],
            's', '"callback -100, 100, doggie"'))

    def test_method_variant(self):
        """test a variant return"""

        def _callback(arg1):
            return int(arg1)

        self.obj = Object(self._service, "/adbus/test/methods", "adbus.test",
                [Method("VariantMethod", _callback, arg_signature='i',
                    return_signature='v')])

        self._loop.run_until_complete(self.call_method("VariantMethod",
            "i", [3245],
            'v', 'i 3245'))

if __name__ == "__main__":
    unittest.main()
