Deriveable types
===========
This module implements deriveable types. The concept is simple, you supply
converters to go from one or more types into another type, then you can
define procedures with a nice type signature and tell the system to derive
the procedure from the converters. This generates a new procedure which takes
the base type, runs all the necessarry converters, and calls the initial
typed procedure.

Example:
In the Jester web framework you get access to the ``Request`` object in your
routes. From this object you're going to extract the information about the
request that you need and then perform the logic of the route. This means
that routes typically contain quite a bit of parsing logic. With this library
you can create procedures that only does the extraction, then procedures
which only does the business logic, and simply tell this library to glue them
together.

.. code-block:: nim

  import jester, strutils, json, deriveables

  type
    UserID = distinct int
    User = object
      name: string

  # Define ways to get various things from a request, this would typically be
  # done with parsing, verification and database access
  proc getUserId(r: Request): UserId {.deriveable.} =
    return UserID(r.params["id"].parseInt)

  proc getUser(u: UserID): User {.deriveable.} =
   # Do database lookup for the user ID and return a user object
   discard

  # You could also attach the deriveable pragma to existing procs instead of
  # the above pragma:
  # deriveable(getUserId, getUser)

  # Define our route bodies purely on our logical types, then derive a
  # procedure from a set of given types
  proc showUser(p: User): string {.derive: Request.} =
    "<html><body>This is the page for user " & p.name & "</body></html>"
    # If you want to automatically convert types to HTML via templates have
    # a look at PMunch/autotemplate

  # Set up our routes, call our logical routes with the request object and
  # the system will figure out how to derive the actual types
  routes:
    get "/user/@id": resp showUser(request)

If a type conversion fails it will throw a ``DerivingError`` which just wraps
the actual error. This means that it's easy to distinguish errors happening
during the conversion and errors happening during the execution of a
procedure itself.

This file is automatically generated from the documentation found in
deriveables.nim. Use ``nim doc src/deriveables.nim`` to get the full documentation.
