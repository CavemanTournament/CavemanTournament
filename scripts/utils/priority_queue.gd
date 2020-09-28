class_name PriorityQueue

var data = []

func push(item, priority: float) -> void:
	self.data.append({"item": item, "priority": priority})
	_up()

func pop():
	if self.data.size() == 0:
		return null

	var top = self.data[0]
	var bottom = self.data.pop_back()

	if self.data.size() > 0:
		self.data[0] = bottom
		_down()

	return top["item"]

func size() -> int:
	return self.data.size()

func _up() -> void:
	var pos = self.data.size() - 1
	var node = self.data[pos]

	while pos > 0:
		var parent = (pos - 1) >> 1
		var current = self.data[parent]

		if _compare(node, current) >= 0:
			break

		self.data[pos] = current
		pos = parent

	self.data[pos] = node

func _down() -> void:
	var pos = 0
	var mid = self.data.size() >> 1
	var node = self.data[pos]

	while pos < mid:
		var best_child = (pos << 1) + 1
		var right = best_child + 1

		if right < self.data.size() && _compare(self.data[right], self.data[best_child]) < 0:
			best_child = right

		if _compare(self.data[best_child], node) >= 0:
			break

		self.data[pos] = self.data[best_child]
		pos = best_child

	self.data[pos] = node

func _compare(item1, item2) -> float:
	return item1["priority"] - item2["priority"]
