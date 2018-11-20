python-adbus
============

D-Bus Binding for Python utilizing the Python's asyncio module.

Status
------

.. image:: https://api.codacy.com/project/badge/Grade/c66c19cdcadd4c83bc4b70596d65aa7a
  :target: https://www.codacy.com/app/ccxtechnologies/python-adbus?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ccxtechnologies/python-adbus&amp;utm_campaign=Badge_Grade

.. image:: https://api.codacy.com/project/badge/Coverage/c66c19cdcadd4c83bc4b70596d65aa7a
  :target: https://www.codacy.com/app/ccxtechnologies/python-adbus?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ccxtechnologies/python-adbus&amp;utm_campaign=Badge_Coverage


Links
-----
- `Documentation <https://ccxtechnologies.github.io/adbus>`_
- `Project Page <https://github.com/ccxtechnologies/adbus>`_
- `Issues <https://github.com/ccxtechnologies/adbus/issues>`_

Dependencies
------------

1. Python >= 3.7
2. libsystemd >= 232 (don’t need systemd, just libsystemd which is a separate package)
3. Cython >= 0.25.2 (only required to regenerate sdbus.c, if you make any changes)

Building / Installing
---------------------

- To build in place for development python ./setup.py build\_ext --inplace
- The html documents are stored in gh-pages branch, so that GitHub will
  serve them as a GitHub Pages. To build them:
  1. check out the gh-pages branch into ../python-adbus/html
  2. cd into docs
  3. sphinx-apidoc -o source/ ../adbus
  4. make html

Unit-Tests
----------

NOTE: Some test-cases require the busctl tool from systemd.

-  To run a specific unit-test from the root directory (eg.): python -m
   unittest tests.test\_sdbus\_method.Test.test\_method\_single\_str

-  To run a specific unit-test module from the root directory (eg.):
   python -m unittest tests.test\_sdbus\_method

-  To run all unit-tests from the root directory: python -m unittest
   discover

Server Examples
---------------

Object Example
~~~~~~~~~~~~~~

This is an example of an object, which can be connected to a service.

.. code-block:: python

  import adbus
  import typing

  class ExampleClass(adbus.server.Object):

      signal1: int = adbus.server.Signal()
      signal2: typing.List[int] = adbus.server.Signal()

      property1: str = adbus.server.Property('none', read_only=True, hidden=True)
      property2: typing.List[int] = adbus.server.Property(['rr', 'ff'], deprectiated=True)

      def __init__(self, service):
          super().__init__(service, path='/xxx/yyy', interface='yyy.xxx')

      @adbus.method(name='test', hidden=True)
      def test_method(self, r: int, gg: str) -> int:
          return r + 10

      def do_something(self):
          self.signal1.emit(14)

Setting Multiple Properties
~~~~~~~~~~~~~~~~~~~~~~~~~~~

It's possible to set multiple properties at the same time, this will defer the property
update signal, and send one signal for all property changes. It's good practice to use
this when changing multiple properties, it will reduce traffic on the D-Bus.

NOTE: Must be running in a loop.


Client Examples
---------------

Accessing Remote Interface via a Proxy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It's possible to map a remote interface to a local instantiated class using a Proxy.

NOTE: If the even loop isn't running no signals will caught, and properties will not
cache (i.e. will read on every access instead of tracking the property changes signals)

**This is a protoype to see how it looks, it hasn't been implemented yet.**

.. code-block:: python

  service = adbus.Service(bus='session')
  proxy = adbus.client.Proxy(service, 'com.example.xxx', '/com/example/Service1',
      interface='com.example.service.unit')

  async def proxy_examples():
    await proxy.update() # initialize the proxy

    # == Access Properties
    await proxy.remote_propertyX.set(45)
    print(await proxy.remote_propertyY.get())

    # == or
    await proxy.remote_propertyX(45)
    print(await proxy.remote_propertyY())

    # == Access Methods
    asyncio.ensure_future(proxy.remote_method_foo("some info")) # don't wait for result
    x = await proxy.remote_method_bar(100, 12, -45) # wait for result

    # == Add a Coroutine to a Signal
    async def local_method(signal_data: int):
      print(signal_data)
    proxy.remote_signal.add(local_method)

    # == or
    proxy.remote_signal(local_method)

    # == Remove a Coroutine to a Signal
    proxy.remote_signal.remove(local_method)

    # == or (if already added)
    proxy.remote_signal(local_method)

    # == Access a method using a different interface name
    proxy['com.example.service.serve'].remote_method_800(b"data")

    # == Create a new proxy from a node in the proxy
    proxy_new = await proxy('Test')

    # == Loop through all nodes in a proxy
    sum_cnt = 0
    async for node in proxy:
        try:
            sum_cnt += await node.count
        except AttributeError:
            pass

    # == set multiple properties in one message (if linked to an adbus based server)
    async with proxy as p:
        p.property1 = "some data"
        p.property2 = [1,2,3,4,5]

  loop = asyncio.get_event_loop()
  loop.run_until_complete(proxy_examples())
  loop.close()

Style Guide
-----------

For a consistent style all code is run through yapf using the Facebook style:

All docstrings are in the google style.

