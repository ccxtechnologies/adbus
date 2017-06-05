#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""test of low-level sd-bus wrapper of an exported method"""

import unittest
import asyncio
import adbus

def callback_str(message):
    """test callback with single string argument, no return"""
    print(message)

class Test(unittest.TestCase):
    """sd-bus wrapper method test cases"""

    def test_method_single_str(self):
        """test method with single string arg and no return"""

        service = adbus.Service("adbus.test")
        service.add("/adbus/test/methods", "adbus.test", [
            adbus.Method("SingleStringArg", callback_str, arg_types='s'),
            ])

        async def run_method():
            """Run the method"""
            for i in range(1, 20):
                print("+"*i)
                await asyncio.sleep(1)
                print("-"*i)
                await asyncio.sleep(1)

        loop = asyncio.get_event_loop()
        service.set_loop(loop)
        loop.run_until_complete(asyncio.gather(
            run_method(),
            #service.mainloop(),
            ))
        loop.close()

if __name__ == "__main__":
    unittest.main()
