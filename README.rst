python-adbus
============

D-Bus Binding for Python supporting coroutines (asyncio)

Status
------

This project is currently under development
===========================================

Dependcies
----------

1. Python >= 3.6
2. libsystemd >= 232 (don’t need systemd, just libsystemd which is a
   seperate package)
3. Cython >= 0.25.2 (only required to regnerate sdbus.c, if you make any
   changes)

Building / Installing
---------------------

-  To build in place for development python ./setup.py build\_ext
   –inplace

Unit-Tests
----------

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

            property1: str = adbus.Property(read_only=False,
                    deprectiated=False, hidden=False, unprivledged=False, emits='change')
            property2: List[int] = adbus.Property(read_only=False,
                    deprectiated=False, hidden=False, unprivledged=False, emits='change')

