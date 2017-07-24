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

Server Example
--------------

.. code-block:: python

  import adbus

  class ExampleClass(adbus.Object):

      signal1: int = adbus.Signal()
      signal2: List[int] = adbus.Signal()

      property1: str = adbus.Property('none', read_only=True, hidden=True)
      property2: List[int] = adbus.Property(['rr', 'ff'],
                  deprectiated=True, emits=None)

      def __init__(self, service):
          adbus.Object.__init__(self, service, path='xxx', interface='xxx')

      @adbus.method(name='test', hidden=True)
      def test_method(self, r: int, gg: str) -> int:
          return r + 10

      def do_something(self):
          f = 14
          self.signal1.emit(f)

Style Guide
-----------

For a consistent style all code is run through yapf using the Facebook style:

All docstings are in the google style.

