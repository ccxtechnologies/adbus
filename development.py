#!/usr/bin/env python3
"""This is just some test code that I use to figure out how thngs work.
    Will be deleted someday."""

from ctypes import cdll

def main():
    """Main test function."""
    print("Starting Devel")

    lib = cdll.LoadLibrary('libdbus-1.so')
    print('Loaded lib {0}'.format(lib))

if __name__ == "__main__":
    main()
