class_name Util

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
	var rect_p1 = Vector2(rect.position.x - floor(w), rect.position.y - floor(w))
	var rect_p2 = Vector2(rect.end.x + ceil(w), rect.position.y - floor(w))
	var rect_p3 = Vector2(rect.end.x + ceil(w), rect.end.y + ceil(w))
	var rect_p4 = Vector2(rect.position.x - floor(w), rect.end.y + ceil(w))

	return (
		Geometry.segment_intersects_segment_2d(p1, p2, rect_p1, rect_p2) ||
		Geometry.segment_intersects_segment_2d(p1, p2, rect_p2, rect_p3) ||
		Geometry.segment_intersects_segment_2d(p1, p2, rect_p3, rect_p4) ||
		Geometry.segment_intersects_segment_2d(p1, p2, rect_p4, rect_p1)
	)

static func rect2_component_equality(rect1, rect2) -> Dictionary:
	return {
		"x": rect1.position.x == rect2.position.x && rect1.end.x == rect2.end.x,
		"y": rect1.position.y == rect2.position.y && rect1.end.y == rect2.end.y
	}
