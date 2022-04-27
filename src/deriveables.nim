import macros, tables, hashes, sequtils, sets

type
  NimTypeNode = distinct NimNode
  DerivingError = object of CatchableError

var routeTypes {.compileTime.}: Table[NimTypeNode, tuple[conv: NimNode, types: seq[NimTypeNode]]]

proc hash(x: NimTypeNode): Hash =
  result = if x.NimNode.getImpl.kind != nnkNilLit:
    hash(x.NimNode.getImpl.repr)
  else:
    hash(x.NimNode.signatureHash)

proc `==`(x, y: NimTypeNode): bool =
  result = if x.NimNode.getImpl.kind != nnkNilLit:
    x.NimNode.getImpl == y.NimNode.getImpl
  else:
    let
      x = if x.NimNode.typeKind == ntyTypedesc: x.NimNode.getType[1] else: x.NimNode.getType
      y = if y.NimNode.typeKind == ntyTypedesc: y.NimNode.getType[1] else: y.NimNode.getType
    x.sameType y

proc `$`(x: NimTypeNode): string =
  x.NimNode.repr

macro derive*(types: typed, ys: varargs[typed]): untyped =
  result = newStmtList()
  for y in ys:
    let
      routeProc = if y.kind == nnkSym: y.getImpl else: y
      initialTypes = (if types.kind == nnkSym: @[types.NimTypeNode] else: types.mapIt(it.NimTypeNode)).toOrderedSet # This must be an ordered set to make sure we generate the paramaters in order
    assert(routeProc.kind == nnkProcDef, "Route handler must be a procedure, got " & $routeProc.kind)
    # Store required types
    var
      mappings: seq[seq[NimNode]]
      visitedTypes = (if types.kind == nnkSym: @[types.NimTypeNode] else: types.mapIt(it.NimTypeNode)).toHashSet # This is the same as initialTypes, but must be a normal hash map
    for i in 1..<routeProc[3].len:
      mappings.add @[]
      var
        requiredTypes: HashSet[NimTypeNode]
        newTypes: HashSet[NimTypeNode]
      requiredTypes.incl routeProc[3][i][1].NimTypeNode
      while requiredTypes.card != 0:
        for t in requiredTypes:
          if t in initialTypes: continue
          elif not routeTypes.hasKey(t):
            error("No procedure defined to get " & $t.repr, t.NimNode)
          else:
            let mapping = routeTypes[t]
            mappings[i-1].insert mapping.conv
            visitedTypes.incl t
            for it in mapping.types:
              newTypes.incl it
        requiredTypes = (requiredTypes + newTypes) - visitedTypes
    # Loop through stack of mappings, generating code to do the conversion
    var
      symbols: Table[NimTypeNode, NimNode]
      callargs = @[routeProc.params[0]]
    for initialType in initialTypes:
      symbols[initialType] = genSym(nskParam, initialType.NimNode.repr)
      callargs.add newIdentDefs(symbols[initialType], initialType.NimNode)
    result.add if y.kind == nnkSym: newEmptyNode() else: y
    var derivedProc =  newProc(ident(routeProc.name.repr), callargs)
    let initialTypesStr = $initialTypes
    for mapping in mappings:
      for map in mapping:
        let
          sym = genSym(nskLet)
          name = map.params[0].repr
        symbols[map.params[0].NimTypeNode] = sym
        var call = newCall(map.name)
        for param in map.params[1..^1]:
          call.add symbols[param[1].NimTypeNode]
        derivedProc.body.add quote do:
          let `sym` =
            try:
              `call`
            except:
              raise newException(DerivingError, "Unable to derive type " & `name` & " from " & `initialTypesStr` & ": " & getCurrentExceptionMsg(), getCurrentException())
    var call = newCall(routeProc.name)
    for param in routeProc.params[1..^1]:
      call.add symbols[param[1].NimTypeNode]
    derivedProc.body.add call
    result.add derivedProc
  #echo result.repr

macro deriveable*(procDefs: varargs[typed]): untyped =
  result = newStmtList()
  for procDef in procDefs:
    let x = if procDef.kind == nnkSym: procDef.getImpl else: procDef
    assert(x.kind == nnkProcDef, "Route handler must be a procedure, but got: " & $x.kind)
    var types: seq[NimTypeNode]
    for t in 1..<x[3].len:
      types.add x[3][t][1].NimTypeNode
    if routeTypes.hasKey(x[3][0].NimTypeNode):
      error("Only one procedure can provide a type, previously defined procedure for type " & x[3][0].repr & " was: " & routeTypes[x[3][0].NimTypeNode].repr, x)
    else:
      routeTypes[x[3][0].NimTypeNode] = (conv: x, types: types)
    if procDef.kind != nnkSym:
      result.add procDef
