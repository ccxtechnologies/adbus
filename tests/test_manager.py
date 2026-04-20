#!/usr/bin/env python3

# Copyright: 2026, CCX Technologies
"""Test the ObjectManager implementation and signal emissions."""

import unittest
import asyncio
import time
from multiprocessing import Process

import adbus

service_name = 'adbus.test.manager'
object_path = '/adbus/test/Manager'
object_interface = 'adbus.test.manager'


class ManagerTestObject(adbus.server.Object):

    def __init__(self, service):
        super().__init__(service, object_path, object_interface, manager=True)

    @adbus.server.method()
    def trigger_object_manager(self) -> None:
        """Trigger explicit interface emissions to test the manager."""
        child_path = object_path + '/TestChild'

        # sd-bus requires an object to actually exist in its internal registry
        # before it can emit InterfacesAdded (it needs to query its properties).
        child = adbus.server.Object(self.service, child_path, object_interface)

        # Test emitting interfaces added and removed
        self.manager.emit_interfaces_added(child_path, [object_interface])
        self.manager.emit_interfaces_removed(child_path, [object_interface])

        # Test emitting full object added and removed
        self.manager.emit_object_added(child_path)
        self.manager.emit_object_removed(child_path)

        # Clean up by detaching the object
        child.detach()


def run_server():
    """Run the test server in a separate process."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    service = adbus.Service(
            service_name,
            bus='session',
            replace_existing=True,
            allow_replacement=True
    )

    # Instantiate the object to attach it to the service
    obj = ManagerTestObject(service)

    async def serve():
        while True:
            await asyncio.sleep(1)

    try:
        loop.run_until_complete(serve())
    except KeyboardInterrupt:
        pass


class TestObjectManager(unittest.TestCase):
    """Test ObjectManager signal listeners and emitters."""

    @classmethod
    def setUpClass(cls):
        # Start the server process
        cls.server = Process(target=run_server, name='run_manager_server')
        cls.server.start()

        # Give the server a moment to register on the D-Bus
        time.sleep(2)

        cls.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(cls.loop)
        cls.service = adbus.Service(bus='session')

    @classmethod
    def tearDownClass(cls):
        # Terminate the background server process
        cls.server.terminate()
        cls.server.join()
        cls.loop.close()

    def test_manager_signals(self):
        signals_received = []

        # When signature is explicitly provided, adbus passes a single list of arguments
        async def added_cb(args):
            path, interfaces = args
            signals_received.append(("InterfacesAdded", path))
            print(f"ObjectManager: Received InterfacesAdded for {path}")

        async def removed_cb(args):
            path, interfaces = args
            signals_received.append(("InterfacesRemoved", path))
            print(f"ObjectManager: Received InterfacesRemoved for {path}")

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

            # Call the server method to trigger the emissions
            print("Triggering ObjectManager emissions...")
            await adbus.client.call(
                    self.service, service_name, object_path, object_interface,
                    "TriggerObjectManager"
            )

            # Give the bus time to propagate the signals back to our client listeners
            await asyncio.sleep(1)

        self.loop.run_until_complete(_test())

        # Verify that we actually received the signals sent by the server
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

        # Verify both add and remove signals were intercepted
        self.assertGreaterEqual(added_count, 1)
        self.assertGreaterEqual(removed_count, 1)


if __name__ == "__main__":
    unittest.main()
