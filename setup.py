#!/usr/bin/python

import subprocess
import sys

from setuptools import setup
from setuptools import find_packages
from setuptools import Extension

try:
    from Cython.Build import cythonize
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False

__module__ = 'adbus'
__url__ = 'https://github.com/ccxtechnologies'

__version__ = None
exec(open(f'{__module__}/__version__.py').read())

# Required for CCX's Build System, do not remove
if "--nosystemd" in sys.argv:
    sys.argv.remove("--nosystemd")


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

ext = '.pyx' if USE_CYTHON else '.c'

module = [Extension(
        f"{__module__}.sdbus",
        sources=[f"{__module__}/sdbus" + ext],
        libraries=["systemd"],
)]


if USE_CYTHON:
    module = cythonize(module)

setup(
        name=__module__,
        version=__version__,
        author='CCX Technologies',
        author_email='charles@ccxtechnologies.com',
        description='asyncio based dbus interface',
        long_description=open('README.rst', 'rt').read(),
        license='MIT',
        url=f'{__url__}/{__module__}',
        download_url=f'{__url__}/archive/v{__version__}.tar.gz',
        python_requires='>=3.7',
        packages=find_packages(exclude=["tests"]),
        setup_requires=[
                'setuptools>=18.0',  # Handles Cython extensions natively
                'cython>=0.25.2',
        ],
        ext_modules=module,
)
