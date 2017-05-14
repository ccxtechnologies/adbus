%module libdbus
%{
#include <dbus/dbus.h>
 %}

%exception(python) {
    int rc;
    rc = $action;

    if (rc == ERR) {
        PyErr_SetString(PyExc_RuntimeError, <err msg>);
        return NULL;
    }

   DBusError err;
   int ret;
   dbus_error_init(&err);


   conn = dbus_bus_get(DBUS_BUS_SESSION, &err);
   if (dbus_error_is_set(&err)) { 
      fprintf(stderr, "Connection Error (%s)\n", err.message); 
      dbus_error_free(&err); 
   }
   if (NULL == conn) { 
      exit(1); 
   }
// request a name on the bus
   ret = dbus_bus_request_name(conn, "test.method.server", 
         DBUS_NAME_FLAG_REPLACE_EXISTING 
         , &err);
   if (dbus_error_is_set(&err)) { 
      fprintf(stderr, "Name Error (%s)\n", err.message); 
      dbus_error_free(&err); 
   }
   if (DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER != ret) { 
      exit(1);
   }
}

