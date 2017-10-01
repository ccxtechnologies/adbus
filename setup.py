#!/usr/bin/python

import sys
import subprocess

from setuptools import setup
from setuptools import find_packages
from setuptools.extension import Extension

__name__ = 'adbus'
__url__ = 'https://github.com/ccxtechnologies'
exec(open(f'{__name__}/__version__.py').read())


def cython(module, libraries):
    if "--cythonize" in sys.argv:
        # Import is here so that don't need cython if don't want
        # to rebuild c file.
        from Cython.Build import cythonize
        sdbus = cythonize(
            [Extension(f"{__name__}.{module}",
                [f"{__name__}/{module}.pyx"], libraries=libraries)]
        )
        sys.argv.remove("--cythonize")
    else:
        sdbus = [Extension(f"{__name__}.{module}",
            [f"{__name__}/{module}.c"], libraries=libraries)]

def check_dependancy(name):
    try:
        whereis = subprocess.run(['whereis', name], check=True, stdout=subprocess.PIPE)
        if b'/' not in whereis.stdout:
            print(f"\033[91m Failed to find dependancy {name}.\033[0m")
            exit(-1)
    except subprocess.CalledProcessError:
        print(f"\033[91m Failed to run whereis, is whereis broken?\033[0m")
        exit(-1)

check_dependancy("libsystemd")

setup(
    name=__name__,
    version=__version__,
    author='CCX Technologies',
    author_email='charles@ccxtechnologies.com',
    description='asyncio based dbus interface',
    license='MIT',
    url=f'{__url__}/{__name__}',
    download_url=f'{__url__}/archive/v{__version__}.tar.gz',

    python_requires='>=3.6',
    packages=find_packages(),
    ext_modules=cython('sdbus', ["systemd"])
)
