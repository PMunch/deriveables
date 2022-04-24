# TODO: Switch to reverse tree structure to allow argument with no direct converter from Request. If Request->X and X->Y exists then Y should be possible as argument. Same if X without arguments is available.
import macros, jester, tables, hashes

type NimTypeNode = distinct NimNode

var
  routeTypes {.compileTime.}: Table[NimTypeNode, seq[NimNode]]
  availableTypes {.compileTime.}: seq[NimTypeNode]

proc hash(x: NimTypeNode): Hash =
  hash(x.NimNode.getTypeImpl.repr)

proc `==`(x, y: NimTypeNode): bool =
  x.NimNode.sameType y.NimNode

macro derive*(y: typed): untyped =
  let
    routeProc = y#.getImpl
    requestSym = bindSym("Request")
  assert(routeProc.kind == nnkProcDef, "Route handler must be a procedure")
  if routeProc[3].len == 2 and routeProc[3][1][1].sameType requestSym:
    echo "Is request"
  else:
    var availableTypes = availableTypes
    for i in 1..<routeProc[3].len:
      if not routeTypes.hasKey(routeProc[3][i][1].NimTypeNode):
        error("No procedure defined to get " & $routeProc[3][i][1].repr, routeProc[3][i][1])
      else:
        var bestCandidate: NimNode
        for conv in routeTypes[routeProc[3][i][1].NimTypeNode]:
          block check:
            for i in 1..<conv[3].len:
              if conv[3][i][1].NimTypeNode notin availableTypes:
                break check
            if bestCandidate == nil or bestCandidate[3].len < conv[3].len:
              bestCandidate = conv
        echo "Best candidate for ", routeProc[3][i].repr, " is ", bestCandidate.repr
        availableTypes.add routeProc[3][i][1].NimTypeNode


macro deriveable*(x: typed): untyped =
  assert(x.kind == nnkProcDef, "Route handler must be a procedure")
  routeTypes.mgetOrPut(x[3][0].NimTypeNode, @[]).add x
  let requestSym = bindSym("Request")
  if x[3].len == 2 and x[3][1][1] == requestSym:
    if availableTypes.len == 0:
      availableTypes.add requestSym.NimTypeNode
    availableTypes.add x[3][0].NimTypeNode

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


proc getUser(r: Request): User {.deriveable.} =
  echo r
  return User(42)

proc getPost(u: User, r: Request): Post {.deriveable.} =
  echo r
  return Post(id: 1, title: "This is a title")

proc getEdit(p: Post, r: Request): Edit {.deriveable.} =
  return Edit(forId: 1, kind: Title, newTitle: "This is a new title")



proc getPost(u: User, p: Post): string {.derive.} =
  echo "Hello world"

static: echo "-----"

proc putEdit(p: Post, e: Edit): string {.derive.} =
  echo "Hello world"

#autoroute("/user/$id/post/$pid", getTest)
#autorouter:
#  get "/user/$id/post/$pid": getTest
