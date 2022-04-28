# To run these tests, simply execute `nimble test`.

import unittest

import deriveables

type
  Test = object
    intField: int
    strField: string
  Double = object
    test: Test
  TypeOne = object
    field: int
  TypeTwo = object
    field: string
  ExpensiveReturn = tuple[one: TypeOne, two: TypeTwo]


proc getInt(x: Test): int {.deriveable.} = x.intField
proc getStr(x: Test): string = x.strField
proc getTest(x: Double): Test = x.test
proc expensive(r: Test): ExpensiveReturn =
  (TypeOne(field: r.intField), TypeTwo(field: r.strField))
proc extractOne(e: ExpensiveReturn): TypeOne = e.one
proc extractTwo(e: ExpensiveReturn): TypeTwo = e.two
deriveable(getStr, getTest, expensive, extractOne, extractTwo)

test "simple derive":
  proc testProc(x: string) {.derive: Test.} =
    check x == "Hello world"
  testProc(Test(intField: 42, strField: "Hello world"))

test "late derive":
  proc testProc(x: string) =
    check x == "Hello world"
  derive(Test, testProc)
  testProc(Test(intField: 42, strField: "Hello world"))

test "double derive":
  proc testProc(x: string) {.derive: Double.} =
    check x == "Hello world"
  testProc(Double(test: Test(intField: 42, strField: "Hello world")))

test "double derive - both fields":
  proc testProc(x: string, y: int) {.derive: Double.} =
    check x == "Hello world"
    check y == 42
  testProc(Double(test: Test(intField: 42, strField: "Hello world")))

test "double derive - extra param":
  proc testProc(x: string, y: int) {.derive: [int, Double].} =
    check x == "Hello world"
    check y == 42
  testProc(42, Double(test: Test(intField: 100, strField: "Hello world")))

test "extract from tuple":
  # This test simulates an expensive procedure which therefore returns two types
  # as a tuple, then we extract each type from the tuple.
  proc testProc(x: TypeOne, y: TypeTwo) {.derive: Test.} =
    check x.field == 42
    check y.field == "Hello world"
  testProc(Test(intField: 42, strField: "Hello world"))
