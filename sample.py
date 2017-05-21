#!/usr/bin/env python3

# Copyright: 2017, Charles Eidsness
# pylint: disable=C0330

"""this is a sample of how the API may look
    NOTE: It doesn't work yet"""

from adbus import Service
from adbus import Object
from adbus import Method
from adbus import Property
from adbus import Signal

class ExampleObject(Object):

    fff: int = 5
    fuf: str = 5

    class __init__(self):
        Object.__init__(self, service, 
                # maybe make the path optional, if not there
                # use the service name and then the class name
                path='/fff/ggg/hhh',
                interface='fff.ggg.hhh',
                # methods could really be anywhere
                methods=[
                    Method('method_x', 'other_name'), 
                    Method('method_y'),
                    ],
                # properties have to be part of this class
                properties=[
                    Property('fff', write=True),
                    Property('fuf'),
                    ]
                )

        #it would be nice to be able to add objects to an object and use
        # its address, etc

        # what about just a single list of items, can we figure out if
        # they are read only props, rw props, methods, signals, or objects?

    class method_x(self, string: str) -> None:
        print(string)
    
    class method_y(self, x: int, y: int) -> int:
        return x + y


