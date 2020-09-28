class_name Util

static func rangef(start: float, end: float, step: float =  1.0):
	var res = []
	var i = start
	while i < end:
		res.push_back(i)
		i += step
	return res

static func random_point_in_circle(radius: float) -> Vector2:
	var t = 2 * PI * randf()
	var u = randf() + randf()
	var r = 2 - u if u > 1 else u
	return Vector2(radius * r * cos(t), radius * r * sin(t))

static func segment_intersects_rect2(
	p1: Vector2,
	p2: Vector2,
	rect: Rect2,
	segment_width: int = 1
) -> bool:
	var w = (float(segment_width) - 1) / 2
	rect = rect.grow(w)

	var min_x = min(p1.x, p2.x)
	var max_x = max(p1.x, p2.x)
	min_x = max(min_x, rect.position.x)
	max_x = min(max_x, rect.end.x)

	if min_x > max_x:
		# Segment is fully on the left or right side of the rectangle
		return false

	var min_y = p1.y
	var max_y = p2.y

	# Calculate y position for segment when x is min_x and max_x
	var dx = p2.x - p1.x
	if abs(dx) > 0.0000001:
		# A line can be represented as (ax + b), so we need to calculate a and b
		# from the given endpoints p1 and p2
		var a = (p2.y - p1.y) / dx
		var b = p1.y - (a * p1.x)
		min_y = (a * min_x) + b
		max_y = (a * max_x) + b

	if min_y > max_y:
		var tmp = max_y
		max_y = min_y
		min_y = tmp

	min_y = max(min_y, rect.position.y)
	max_y = min(max_y, rect.end.y)

	# Segment intersects if it's not fully above or below the rectangle
	return min_y <= max_y

static func rect2_component_equality(rect1, rect2) -> Dictionary:
	return {
		"x": rect1.position.x == rect2.position.x && rect1.end.x == rect2.end.x,
		"y": rect1.position.y == rect2.position.y && rect1.end.y == rect2.end.y
	}

static func filter(filter_function: FuncRef, arr: Array) -> Array:
	var results = []
	for value in arr:
		if filter_function.call_func(value):
			results.append(value)
	return results
