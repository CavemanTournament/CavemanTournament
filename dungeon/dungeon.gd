extends Reference

class_name Dungeon

var cells: Dictionary
var tree: RTree
var next_cell_id: int

func _init():
	self.cells = {}
	self.tree = RTree.new()
	self.next_cell_id = 0

func add_cell(pos: Vector2, size: Vector2) -> DungeonCell:
	var cell: = DungeonCell.new(_get_unused_cell_id())
	cell.set_position(pos)
	cell.set_size(size)
	self.cells[cell.id] = cell
	self.tree.insert(cell.id, cell.rect)
	return cell

func remove_cell(id: int) -> void:
	self.cells.erase(id)
	self.tree.remove(id)

func get_cells() -> Array:
	return self.cells.values()

func get_cell(id: int) -> DungeonCell:
	return self.cells[id]

func move_cell(id: int, delta: Vector2) -> void:
	position_cell(id, get_cell(id).pos + delta)

func position_cell(id: int, pos: Vector2) -> void:
	var cell = get_cell(id)
	cell.set_position(pos)
	self.tree.update(id, cell.rect)

func merge_cell(id: int, r: Rect2) -> bool:
	var cell = get_cell(id)
	if cell.merge_rect(r):
		self.tree.update(id, cell.rect)
		return true

	return false

func cells_overlapping_cell(id: int) -> Array:
	return self.tree.query_rect2(self.cells[id].rect)

func cells_overlapping_point(point: Vector2) -> Array:
	return self.tree.query_point(point)

func cells_overlapping_path(path: Array, segment_width: = 1) -> Array:
	var cells = []
	for i in range(path.size() - 1):
		cells += cells_overlapping_segment(path[i], path[i + 1], segment_width)
	return cells

func cells_overlapping_segment(from: Vector2, to: Vector2, segment_width: = 1) -> Array:
	return self.tree.query_segment(from, to, segment_width)

func _get_unused_cell_id() -> int:
	var id: = self.next_cell_id
	self.next_cell_id += 1
	return id
