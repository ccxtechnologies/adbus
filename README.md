# async-dbus-python
D-Bus Binding for Python supporting coroutines (asyncio)

# This project is currently under development

- Currently developing it using the systemd dbus library, you will need 
libsystemd to use it. I'm using version 232, but older versions may work. NOTE: You don't have to use systemd to have libsystemd on your system.

- This module uses typing, coroutines, and format strings so it will
only ever work with > version 3.6 or Python
