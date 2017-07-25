python-adbus
============

D-Bus Binding for Python based on the asyncio mainloop.

Status
------

**NOTE: This project is currently under development**

Dependencies
------------

1. Python >= 3.6
2. libsystemd >= 232 (don’t need systemd, just libsystemd which is a separate package)
3. Cython >= 0.25.2 (only required to regenerate sdbus.c, if you make any changes)

Building / Installing
---------------------

-  To build in place for development python ./setup.py build\_ext –inplace

Unit-Tests
----------

NOTE: Some test-cases require the busctl tool from systemd.

-  To run a specific unit-test from the root directory (eg.): python -m
   unittest tests.test\_sdbus\_method.Test.test\_method\_single\_str

-  To run a specific unit-test module from the root directory (eg.):
   python -m unittest tests.test\_sdbus\_method

-  To run all unit-tests from the root directory: python -m unittest
   discover

Object Example
--------------

This is an example of an object, which can be connected to a service.

.. code-block:: python

  import adbus
  import typing

  class ExampleClass(adbus.server.Object):

      signal1: int = adbus.server.Signal()
      signal2: List[int] = adbus.server.Signal()

      property1: str = adbus.server.Property('none', read_only=True, hidden=True)
      property2: typing.List[int] = adbus.server.Property(['rr', 'ff'], deprectiated=True)

      def __init__(self, service):
          super().__init__(service, path='/xxx/yyy', interface='yyy.xxx')

      @adbus.method(name='test', hidden=True)
      def test_method(self, r: int, gg: str) -> int:
          return r + 10

Setting Multiple Properties
---------------------------

It's possible to set multiple properties at the same time, this will defer the property
update signal, and send one signal for all property changes. It's good practice to use
this when changing multiple properties, it will reduce traffic on the D-Bus.

NOTE: If the even loop isn't running no signals will be emitted.

.. code-block:: python

  service = adbus.server.Service(service_name, bus='session')
  obj = TestObject(service)

  async def set_props(obj):
    with obj as o:
          o.property1 = 'yellow'
          o.property2 = 42
          o.property3 = [6,7,10,43,102]

  asyncio.get_event_loop().run_until_complete(set_props(obj))

Style Guide
-----------

For a consistent style all code is run through yapf using the Facebook style:

All docstings are in the google style.

