#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""distutils build and configuration script for async-dbus-python."""

from distutils.core import setup
from distutils.core import Extension
import subprocess

def pkgconfig(*packages, **kw):
    """Calls pkg-config to get library c-flags."""

    config = kw.setdefault('config', {})
    optional_args = kw.setdefault('optional', '')

    flag_map = {'include_dirs': ['--cflags-only-I', 2],
            'library_dirs': ['--libs-only-L', 2],
            'libraries': ['--libs-only-l', 2],
            'extra_compile_args': ['--cflags-only-other', 0],
            'extra_link_args': ['--libs-only-other', 0],
            }
    for package in packages:
        for distutils_key, (pkg_option, _n) in flag_map.items():
            items = subprocess.check_output(['pkg-config', optional_args,
                pkg_option, package]).decode('utf8').split()
            config.setdefault(distutils_key, []).extend([i[_n:] for i in items])
    return config

def main():
    """Main Function."""

    libdbus = Extension('libdbus', sources=['libdbus_wrap.c'], **pkgconfig('dbus-1'))

    setup(name='async-dbus',
            version='1.0',
            description='This is a demo package',
            ext_modules=[libdbus])

if __name__ == "__main__":
    main()
