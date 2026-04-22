#!/usr/bin/env python3

# Copyright: 2026, CCX Technologies
"""Test the ObjectManager wrapper methods on adbus.server.Object."""

import unittest
import asyncio
import time
from multiprocessing import Process

import adbus
import adbus.server
import adbus.client

service_name = 'adbus.test.objectmanager'
object_path = '/adbus/test/Manager'
object_interface = 'adbus.test.manager'


class ManagerTestObject(adbus.server.Object):
    """Test object initialized with an ObjectManager attached."""

    def __init__(self, service):
        # Setting manager=True initializes the underlying sdbus.Manager
        super().__init__(service, object_path, object_interface, manager=True)

    @adbus.server.method()
    def trigger_emissions(self) -> None:
        """Trigger explicit interface emissions using the new wrapper methods."""
        child_path = object_path + '/TestChild'

        # sd-bus requires an object to actually exist in its internal registry
        # before it can emit InterfacesAdded (it needs to query its properties).
        child = adbus.server.Object(self.service, child_path, object_interface)

        # Test the wrapper methods directly on the Object instance
        self.emit_interfaces_added(child_path, [object_interface])
        self.emit_interfaces_removed(child_path, [object_interface])

        self.emit_object_added(child_path)
        self.emit_object_removed(child_path)

        # Clean up by detaching the mock child object
        child.detach()


def run_server():
    """Run the test server in a separate background process."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    service = adbus.Service(
            service_name,
            bus='session',
            replace_existing=True,
            allow_replacement=True
    )

    # Instantiate the root object (which has manager=True)
    obj = ManagerTestObject(service)

    async def serve():
        while True:
            await asyncio.sleep(1)

    try:
        loop.run_until_complete(serve())
    except KeyboardInterrupt:
        pass


class TestObjectManagerWrapper(unittest.TestCase):
    """Test ObjectManager signal wrapper methods on adbus.server.Object."""

    @classmethod
    def setUpClass(cls):
        # 1. Start the server daemon process
        cls.server = Process(target=run_server, name='run_manager_server')
        cls.server.start()

        # Give the server a moment to attach its DBus connection
        time.sleep(2)

        cls.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(cls.loop)
        cls.service = adbus.Service(bus='session')

    @classmethod
    def tearDownClass(cls):
        # 2. Terminate the background server process
        cls.server.terminate()
        cls.server.join()
        cls.loop.close()

    def test_manager_wrapper_signals(self):
        signals_received = []

        async def added_cb(args):
            path, interfaces = args
            signals_received.append(("InterfacesAdded", path))
            print(f"Signal Received: InterfacesAdded for {path}")

        async def removed_cb(args):
            path, interfaces = args
            signals_received.append(("InterfacesRemoved", path))
            print(f"Signal Received: InterfacesRemoved for {path}")

        async def _test():
            # Setup listeners for standard ObjectManager signals
            listen_add = adbus.client.Listen(
                    self.service,
                    service_name,
                    object_path,
                    "org.freedesktop.DBus.ObjectManager",
                    "InterfacesAdded",
                    added_cb,
                    signature="oa{sa{sv}}"
            )

            listen_rem = adbus.client.Listen(
                    self.service,
                    service_name,
                    object_path,
                    "org.freedesktop.DBus.ObjectManager",
                    "InterfacesRemoved",
                    removed_cb,
                    signature="oas"
            )

            # Call the server method to trigger the wrapper emissions
            print(
                    "Triggering ObjectManager emissions via adbus.server.Object wrappers..."
            )
            await adbus.client.call(
                    self.service, service_name, object_path, object_interface,
                    "TriggerEmissions"
            )

            # Give the bus time to propagate the signals back to our client listeners
            await asyncio.sleep(1)

        self.loop.run_until_complete(_test())

        # Verify that we actually received the signals dispatched by the wrapper methods
        self.assertTrue(
                len(signals_received) > 0,
                "Failed to receive ObjectManager signals"
        )

        added_count = sum(
                1 for s in signals_received if s[0] == "InterfacesAdded"
        )
        removed_count = sum(
                1 for s in signals_received if s[0] == "InterfacesRemoved"
        )

        # Assert we caught the signals
        self.assertGreaterEqual(
                added_count, 1,
                "Failed to receive InterfacesAdded signal via wrapper"
        )
        self.assertGreaterEqual(
                removed_count, 1,
                "Failed to receive InterfacesRemoved signal via wrapper"
        )


if __name__ == "__main__":
    unittest.main()
