class_name TestCase
extends RefCounted

## Base class for all Botanical Haven test cases.
## Provides assertion helpers and isolation support.
## Tests must be stateless - no permanent side effects.

var test_name: String = ""
var _results: Array[Dictionary] = []
var _current_test: String = ""

# ---------- Assertion API ----------

func assert_true(condition: bool, msg: String = "") -> void:
	if condition:
		_pass(msg if msg else "assert_true")
	else:
		_fail("assert_true FAILED" + (" — " + msg if msg else ""))

func assert_false(condition: bool, msg: String = "") -> void:
	if not condition:
		_pass(msg if msg else "assert_false")
	else:
		_fail("assert_false FAILED" + (" — " + msg if msg else ""))

func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	if a == b:
		_pass(msg if msg else "assert_eq")
	else:
		_fail("assert_eq FAILED: %s != %s%s" % [str(a), str(b), (" — " + msg if msg else "")])

func assert_ne(a: Variant, b: Variant, msg: String = "") -> void:
	if a != b:
		_pass(msg if msg else "assert_ne")
	else:
		_fail("assert_ne FAILED: %s == %s%s" % [str(a), str(b), (" — " + msg if msg else "")])

func assert_gt(a: Variant, b: Variant, msg: String = "") -> void:
	if a > b:
		_pass(msg if msg else "assert_gt")
	else:
		_fail("assert_gt FAILED: %s not > %s%s" % [str(a), str(b), (" — " + msg if msg else "")])

func assert_lt(a: Variant, b: Variant, msg: String = "") -> void:
	if a < b:
		_pass(msg if msg else "assert_lt")
	else:
		_fail("assert_lt FAILED: %s not < %s%s" % [str(a), str(b), (" — " + msg if msg else "")])

func assert_gte(a: Variant, b: Variant, msg: String = "") -> void:
	if a >= b:
		_pass(msg if msg else "assert_gte")
	else:
		_fail("assert_gte FAILED: %s not >= %s%s" % [str(a), str(b), (" — " + msg if msg else "")])

func assert_lte(a: Variant, b: Variant, msg: String = "") -> void:
	if a <= b:
		_pass(msg if msg else "assert_lte")
	else:
		_fail("assert_lte FAILED: %s not <= %s%s" % [str(a), str(b), (" — " + msg if msg else "")])


func assert_has(collection: Variant, key: Variant, msg: String = "") -> void:
	var found = false
	if collection is Dictionary: found = collection.has(key)
	elif collection is Array: found = collection.has(key)
	if found:
		_pass(msg if msg else "assert_has")
	else:
		_fail("assert_has FAILED: key '%s' not found%s" % [str(key), (" — " + msg if msg else "")])

func assert_not_empty(collection: Variant, msg: String = "") -> void:
	var empty = true
	if collection is Dictionary: empty = collection.is_empty()
	elif collection is Array: empty = collection.is_empty()
	elif collection is String: empty = collection.is_empty()
	if not empty:
		_pass(msg if msg else "assert_not_empty")
	else:
		_fail("assert_not_empty FAILED%s" % (" — " + msg if msg else ""))

func assert_approx_eq(a: float, b: float, tolerance: float = 0.001, msg: String = "") -> void:
	if abs(a - b) <= tolerance:
		_pass(msg if msg else "assert_approx_eq")
	else:
		_fail("assert_approx_eq FAILED: |%f - %f| = %f > %f%s" % [a, b, abs(a - b), tolerance, (" — " + msg if msg else "")])

# ---------- Test Context ----------

func begin_test(name: String) -> void:
	_current_test = name

func get_results() -> Array[Dictionary]:
	return _results

func get_pass_count() -> int:
	return _results.filter(func(r): return r.get("status") == "PASS").size()

func get_fail_count() -> int:
	return _results.filter(func(r): return r.get("status") == "FAIL").size()

# ---------- Internal ----------

func _pass(msg: String) -> void:
	_results.append({"test": _current_test, "assertion": msg, "status": "PASS"})

func _fail(msg: String) -> void:
	_results.append({"test": _current_test, "assertion": msg, "status": "FAIL"})
	push_warning("[TestCase] FAIL in '%s': %s" % [_current_test, msg])
