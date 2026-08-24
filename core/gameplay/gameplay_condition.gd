class_name GameplayCondition
extends RefCounted

## Universal Data-Driven Condition Evaluator for Gameplay Rules (Phase 39).
## Supports dot-notation context traversal, standard operators, array checks, and nested AND/OR/NOT trees.

enum LogicOp { ALL, ANY, NONE }

static func evaluate(cond_data: Variant, context: Dictionary) -> bool:
	if cond_data == null: return true
	if cond_data is bool: return cond_data
	if not (cond_data is Dictionary): return true
	if cond_data.is_empty(): return true
	
	# 1. Compound Combinators: "and" / "all"
	if cond_data.has("and") or cond_data.has("all"):
		var list = cond_data.get("and", cond_data.get("all", []))
		if list is Array:
			for sub in list:
				if not evaluate(sub, context): return false
			return true
			
	# 2. Compound Combinators: "or" / "any"
	if cond_data.has("or") or cond_data.has("any"):
		var list = cond_data.get("or", cond_data.get("any", []))
		if list is Array:
			if list.is_empty(): return true
			for sub in list:
				if evaluate(sub, context): return true
			return false
			
	# 3. Compound Combinators: "not" / "none"
	if cond_data.has("not") or cond_data.has("none"):
		var sub = cond_data.get("not", cond_data.get("none", {}))
		if sub is Array:
			for item in sub:
				if evaluate(item, context): return false
			return true
		else:
			return not evaluate(sub, context)

	# 4. Atomic Condition
	var path = str(cond_data.get("path", cond_data.get("key", cond_data.get("field", ""))))
	var op = str(cond_data.get("op", cond_data.get("operator", "equals"))).to_lower()
	var expected = cond_data.get("value", cond_data.get("target", true))
	
	if path == "": return true
	var actual = resolve_path(context, path)
	
	return evaluate_atomic(actual, op, expected)

static func resolve_path(context: Dictionary, path: String) -> Variant:
	if path == "": return null
	if context.has(path): return context[path]
	
	var segments = path.split(".")
	var curr: Variant = context
	for seg in segments:
		if curr is Dictionary:
			if curr.has(seg):
				curr = curr[seg]
			else:
				return null
		elif curr is Object and curr.has_method("get"):
			curr = curr.get(seg)
		else:
			return null
	return curr

static func evaluate_atomic(actual: Variant, op: String, expected: Variant) -> bool:
	match op:
		"equals", "==", "eq", "is":
			return _values_equal(actual, expected)
		"not_equals", "!=", "neq", "is_not":
			return not _values_equal(actual, expected)
		"greater_than", ">", "gt":
			if actual == null or expected == null: return false
			return float(actual) > float(expected)
		"less_than", "<", "lt":
			if actual == null or expected == null: return false
			return float(actual) < float(expected)
		"greater_or_equal", ">=", "gte", "ge":
			if actual == null or expected == null: return false
			return float(actual) >= float(expected)
		"less_or_equal", "<=", "lte", "le":
			if actual == null or expected == null: return false
			return float(actual) <= float(expected)
		"contains", "has", "in":
			if actual == null: return false
			if actual is Array: return actual.has(expected)
			if actual is Dictionary: return actual.has(expected)
			if actual is String: return str(actual).contains(str(expected))
			return false
		"not_contains", "!has", "not_in":
			if actual == null: return true
			if actual is Array: return not actual.has(expected)
			if actual is Dictionary: return not actual.has(expected)
			if actual is String: return not str(actual).contains(str(expected))
			return true
		"exists", "is_set":
			return actual != null
		"not_exists", "is_null":
			return actual == null
		"in_range", "between":
			if expected is Array and expected.size() >= 2:
				var min_v = float(expected[0])
				var max_v = float(expected[1])
				var v = float(actual) if actual != null else 0.0
				return v >= min_v and v <= max_v
			return false
		_:
			return _values_equal(actual, expected)

static func _values_equal(a: Variant, b: Variant) -> bool:
	if a == null and b == null: return true
	if a == null or b == null: return false
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is bool or b is bool:
		return bool(a) == bool(b)
	return str(a) == str(b)
