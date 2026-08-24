class_name SafeExpressionEvaluator
extends RefCounted

## Sandboxed Declarative Expression & Condition Evaluator (Phase 42).
## Evaluates user-authored gameplay expressions without raw eval() or code injection.

static func evaluate(expression_dict: Dictionary, context: Dictionary) -> bool:
	if expression_dict.is_empty(): return true
	
	# Compound AND
	if expression_dict.has("and") or expression_dict.has("all"):
		var list = expression_dict.get("and", expression_dict.get("all", []))
		if list is Array:
			for sub in list:
				if not evaluate(sub, context): return false
			return true
			
	# Compound OR
	if expression_dict.has("or") or expression_dict.has("any"):
		var list = expression_dict.get("or", expression_dict.get("any", []))
		if list is Array:
			if list.is_empty(): return true
			for sub in list:
				if evaluate(sub, context): return true
			return false
			
	# Compound NOT
	if expression_dict.has("not"):
		var sub = expression_dict["not"]
		return not evaluate(sub, context)

	# Atomic Comparison: left, op, right
	var left_val = resolve_value(expression_dict.get("left", expression_dict.get("path", "")), context)
	var op = str(expression_dict.get("op", expression_dict.get("operator", "=="))).to_lower()
	var right_val = expression_dict.get("right", expression_dict.get("value", null))
	
	if right_val is String and str(right_val).begins_with("@"):
		# Reference to another context variable
		right_val = resolve_value(str(right_val).trim_prefix("@"), context)
		
	return compare(left_val, op, right_val)

static func resolve_value(accessor: Variant, context: Dictionary) -> Variant:
	if not (accessor is String): return accessor
	var key = str(accessor).strip_edges()
	if key == "": return null
	if context.has(key): return context[key]
	
	var segments = key.split(".")
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

static func compare(actual: Variant, op: String, expected: Variant) -> bool:
	match op:
		"==", "equals", "eq", "is":
			if (actual is int or actual is float) and (expected is int or expected is float):
				return is_equal_approx(float(actual), float(expected))
			if actual is bool or expected is bool:
				return bool(actual) == bool(expected)
			return str(actual) == str(expected)
		"!=", "not_equals", "neq":
			return not compare(actual, "==", expected)
		">", "gt", "greater_than":
			if actual == null or expected == null: return false
			return float(actual) > float(expected)
		"<", "lt", "less_than":
			if actual == null or expected == null: return false
			return float(actual) < float(expected)
		">=", "gte", "greater_or_equal":
			if actual == null or expected == null: return false
			return float(actual) >= float(expected)
		"<=", "lte", "less_or_equal":
			if actual == null or expected == null: return false
			return float(actual) <= float(expected)
		"contains", "has", "in":
			if actual is Array: return actual.has(expected)
			if actual is Dictionary: return actual.has(expected)
			if actual is String: return str(actual).contains(str(expected))
			return false
		_:
			return compare(actual, "==", expected)
