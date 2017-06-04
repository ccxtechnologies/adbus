#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
from adbus import _sdbus

def callback_str(message):
    """test callback with single string argument, no return"""
    print(message)

class Test(unittest.TestCase):
    """sd-bus wrapper method test cases"""

    def test_method_single_str(self):
        """test method with single string arg and no return"""

        l = asyncio.get_event_loop()
        p = ThreadPoolExecutor(3)

        s = _sdbus.Service(b"adbus.test")
        m = [_sdbus.Method(b"SingleStringArg", callback_str, arg_types=b's')]
        o = _sdbus.Object(s, b"/adbus/test/methods", b"adbus.test", m)
        
        async def run_method():
            """Run the method"""
            while True:
                print("++++++++++++++++++++++")
                await asyncio.sleep(1)
                print("----------------------")
                await asyncio.sleep(1)

        def block():
            print("-+-+-+-+-+-+-")
            time.sleep(2)

        async def looperX():
            while True:
                await l.run_in_executor(p, block)
                await l.run_in_executor(p, s._bus_process)
                await l.run_in_executor(p, s._bus_wait)

        l.run_until_complete(asyncio.gather(
            looperX(),
            run_method(),
            ))
        l.close()

if __name__ == "__main__":
    unittest.main()
