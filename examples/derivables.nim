import jester, strutils, json, deriveables

type
  User = distinct int
  Post = object
    id: int
    title: string
    body: string
  EditKind = enum Title, Body
  Edit = object
    forId: int
    case kind: EditKind
    of Title: newTitle: string
    of Body: newBody: string

# Define ways to get various things from a request, this would typically be done with parsing, verification and database access
proc getUser(r: Request): User {.deriveable.} =
  return User(r.params["id"].parseInt)

proc getPost(u: User, r: Request): Post {.deriveable.} =
  if u.int == 100:
    return Post(id: r.params["pid"].parseInt, title: "This is a title")
  else:
    raise newException(KeyError, "Unable to get post for user")

proc getEdit(p: Post, r: Request): Edit =
  let edit = r.body.parseJson
  result = Edit(forId: edit["id"].getInt, kind: edit["kind"].getStr.parseEnum[:EditKind])
  case result.kind:
  of Title: result.newTitle = edit["newTitle"].getStr
  of Body: result.newBody = edit["newBody"].getStr

deriveable(getEdit) # Can also add a derivation after the definition of a procedure

# Define our route bodies purely on our logical types, then derive a called from a set of given types
proc getPost(p: Post): string {.derive: Request.} =
  $p

proc putEdit(p: Post, e: Edit): string =
  echo "Changing \"", p.title, "\" to \"", e.newTitle, "\""

derive(Request, putEdit) # Can also derive a procedure after the definition

# Set up our routes, call our logical routes with the request object and the system will figure out how to derive the actual types
routes:
  get "/user/@id/post/@pid": resp getPost(request)
  put "/user/@id/post/@pid": resp putEdit(request)
