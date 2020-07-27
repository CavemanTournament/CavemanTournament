class_name Util

static func random_point_in_circle(_radius: float):
  var t = 2 * PI * randf()
  var u = randf() + randf()
  var r = 2 - u if u > 1 else u
  return Vector2(_radius * r * cos(t), _radius * r * sin(t))

static func segment_intersects_rect2(
	_p1: Vector2,
	_p2: Vector2,
	_rect: Rect2,
	_segment_width: int = 1
):
	var w = (float(_segment_width) - 1) / 2
	var rect_p1 = Vector2(_rect.position.x - floor(w), _rect.position.y - floor(w))
	var rect_p2 = Vector2(_rect.end.x + ceil(w), _rect.position.y - floor(w))
	var rect_p3 = Vector2(_rect.end.x + ceil(w), _rect.end.y + ceil(w))
	var rect_p4 = Vector2(_rect.position.x - floor(w), _rect.end.y + ceil(w))

	return (
		Geometry.segment_intersects_segment_2d(_p1, _p2, rect_p1, rect_p2) ||
		Geometry.segment_intersects_segment_2d(_p1, _p2, rect_p2, rect_p3) ||
		Geometry.segment_intersects_segment_2d(_p1, _p2, rect_p3, rect_p4) ||
		Geometry.segment_intersects_segment_2d(_p1, _p2, rect_p4, rect_p1)
	)

static func rect2_component_equality(_rect1, _rect2):
	return {
		"x": _rect1.position.x == _rect2.position.x && _rect1.end.x == _rect2.end.x,
		"y": _rect1.position.y == _rect2.position.y && _rect1.end.y == _rect2.end.y
	}
