#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
from adbus import _sdbus

def callback_str(message):
    """test callback with single string argument, no return"""
    print(message)

class Test(unittest.TestCase):
    """sd-bus wrapper method test cases"""

    def test_method_single_str(self):
        """test method with single string arg and no return"""

        async def run_method():
            """Run the method"""
            print("FFFF")
            await asyncio.sleep(1)
            print("FFFF")
            #future.set_result('Complete')

        s = _sdbus.Service(b"adbus.test")
        m = [_sdbus.Method(b"SingleStringArg", callback_str, arg_types=b's')]
        o = _sdbus.Object(s, b"/adbus/test/methods", b"adbus.test", m)

        loop = asyncio.get_event_loop()
        #future = asyncio.Future()
        #asyncio.ensure_future(run_method(future))
        loop.run_until_complete(asyncio.gather(
            s.process(),
            run_method(),
            ))
        #print(future.result())
        loop.close()

if __name__ == "__main__":
    unittest.main()
