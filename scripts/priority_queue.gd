class_name PriorityQueue

var data = []

func push(_item, _priority):
	data.append({"item": _item, "priority": _priority})
	_up()

func pop():
	if data.size() == 0:
		return null

	var top = data[0]
	var bottom = data.pop_back()

	if data.size() > 0:
		data[0] = bottom
		_down()

	return top["item"]

func size():
	return data.size()

func _up():
	var pos = data.size() - 1
	var node = data[pos]

	while pos > 0:
		var parent = (pos - 1) >> 1
		var current = data[parent]

		if _compare(node, current) >= 0:
			break

		data[pos] = current
		pos = parent

	data[pos] = node

func _down():
	var pos = 0
	var mid = data.size() >> 1
	var node = data[pos]

	while pos < mid:
		var best_child = (pos << 1) + 1
		var right = best_child + 1

		if right < data.size() && _compare(data[right], data[best_child]) < 0:
			best_child = right

		if _compare(data[best_child], node) >= 0:
			break

		data[pos] = data[best_child]
		pos = best_child

	data[pos] = node

func _compare(_item1, _item2):
	return _item1["priority"] - _item2["priority"]
