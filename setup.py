#!/usr/bin/python

import sys
import subprocess

from setuptools import setup
from setuptools import find_packages
from setuptools.extension import Extension

__module__ = 'adbus'
__url__ = 'https://github.com/ccxtechnologies'

__version__ = None
exec(open(f'{__module__}/__version__.py').read())

if "--nosystemd" in sys.argv:
    sys.argv.remove("--nosystemd")


def cython(module, libraries):
    if "--cythonize" in sys.argv:
        sys.argv.remove("--cythonize")
        from Cython.Build import cythonize
        return cythonize(
                [
                        Extension(
                                f"{__module__}.{module}",
                                [f"{__module__}/{module}.pyx"],
                                libraries=libraries
                        )
                ]
        )
    else:
        return [
                Extension(
                        f"{__module__}.{module}", [f"{__module__}/{module}.c"],
                        libraries=libraries
                )
        ]


def check_external_dependancy(name):
    try:
        whereis = subprocess.run(
                ['whereis', name], check=True, stdout=subprocess.PIPE
        )
        if b'/' not in whereis.stdout:
            print(f"\033[91m Failed to find dependency {name}.\033[0m")
    except subprocess.CalledProcessError:
        print(f"\033[91m Failed to run whereis, is whereis broken?\033[0m")


check_external_dependancy("libsystemd")

setup(
        name=__module__,
        version=__version__,
        author='CCX Technologies',
        author_email='charles@ccxtechnologies.com',
        description='asyncio based dbus interface',
        license='MIT',
        url=f'{__url__}/{__module__}',
        download_url=f'{__url__}/archive/v{__version__}.tar.gz',
        python_requires='>=3.7',
        packages=find_packages(exclude=["tests"]),
        ext_modules=cython('sdbus', ["systemd"])
)
