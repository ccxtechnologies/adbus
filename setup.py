#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""distutils build and configuration script for async-dbus-python."""

from distutils.core import setup
from distutils.core import Extension

def build():
    """Build Package."""

    try:
        from Cython.Build import cythonize
        sdbus = cythonize(Extension("adbus._sdbus", ["adbus/_sdbus.pyx"],
                libraries=['systemd']))

    except ImportError:
        sdbus = [Extension("adbus._sdbus", ["adbus/_sdbus.c"],
                libraries=['systemd'])]

    setup(name='adbus',
            version='0.1',
            description='asyncio based dbus interface',
            license='MIT',
            author='Charles Eidsness',
            author_email='charles.eidsness@ieee.org',
            url='http://github.com/charleseidsness/async-dbus-python',
            platforms=['linux'],
            provides=['adbus'],
            packages=['adbus'],
            ext_modules=sdbus
            )

if __name__ == "__main__":
    build()
