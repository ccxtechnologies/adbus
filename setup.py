#!/usr/bin/python

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

ext = '.pyx' if USE_CYTHON else '.c'

module = [
        Extension(
                f"{__module__}.sdbus",
                sources=[f"{__module__}/sdbus" + ext],
                libraries=["systemd"],
                extra_compile_args=["-O3", "-std=c99"],  # match systemd
        )
]

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
