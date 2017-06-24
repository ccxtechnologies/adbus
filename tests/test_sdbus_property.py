#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness

"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
import asyncio.subprocess
from adbus.server.service import Service
from adbus.server.property import Property

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
        print('='*loops)
        for _ in range(1, loops+1):
            print('+', end='', flush=True)
            await asyncio.sleep(1)
        print('\n' + '='*loops)

    async def get_property(self, name, signature, attr_name):
        """get a property via d-bus"""

        service = 'adbus.test'
        path = '/adbus/test/methods'
        interface = 'adbus.test'

        cmd = f'busctl --user -- get-property {service} {path} {interface} {name}'

        create = asyncio.create_subprocess_shell(cmd,
                stdout=asyncio.subprocess.PIPE)

        proc = await create

        # Read one line of output
        data = await proc.stdout.readline()
        line = data.decode('ascii').rstrip()

        self.assertEqual(line, f'{signature} {getattr(self, attr_name)}')

    async def set_property(self, name, signature, attr_name, value):
        """set a property via d-bus"""

        service = 'adbus.test'
        path = '/adbus/test/methods'
        interface = 'adbus.test'

        cmd = f'busctl --user -- set-property {service} {path} {interface} {name} {signature} {value}'

        create = asyncio.create_subprocess_shell(cmd,
                stdout=asyncio.subprocess.PIPE)

        proc = await create

        await proc.stdout.readline()

        self.assertEqual(value, getattr(self, attr_name))

    def test_property_basic(self):
        """test a basic method"""

        async def test_seq():
            await self.get_property("Basic", 'i', "test_prop")
            await self.set_property("Basic", 'i', "test_prop", -1267)

        self._service.add_object("/adbus/test/methods", "adbus.test",
                [Property("Basic", self, 'test_prop', signature='i')])

        self._loop.run_until_complete(test_seq())

if __name__ == "__main__":
    unittest.main()
