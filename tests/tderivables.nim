# To run these tests, simply execute `nimble test`.

import unittest

import deriveables

type
  Test = object
    intField: int
    strField: string
  Double = object
    test: Test

proc getInt(x: Test): int    = x.intField
proc getStr(x: Test): string = x.strField
proc getTest(x: Double): Test = x.test
deriveable(getInt, getStr, getTest)

test "simple derive":
  proc testProc(x: string) {.derive: Test.} =
    check x == "Hello world"
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
