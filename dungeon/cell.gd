extends Reference

class_name DungeonCell

var id: int
var height: float
var pos: = Vector2()
var rect: = Rect2()
var type: int = DungeonVariables.CellType.NONE

func _init(_id: int):
	self.id = _id

func distance_to(cell: DungeonCell) -> float:
	return self.pos.distance_to(cell.pos)

func vector_to(cell: DungeonCell) -> Vector2:
	return self.pos - cell.pos

func set_size(size: Vector2) -> void:
	self.height = size.y

	var x = self.pos.x - (size.x / 2)
	var z = self.pos.y - (size.y / 2)
	set_rect(Rect2(x, z, size.x, size.y))

func get_size() -> Vector2:
	return self.rect.size

func move(translation: Vector2) -> void:
	set_position(self.pos + translation)

func set_position(_pos: Vector2) -> void:
	self.pos = _pos
	self.rect = Rect2(
		self.pos.x - (self.rect.size.x / 2),
		self.pos.y - (self.rect.size.y / 2),
		self.rect.size.x,
		self.rect.size.y
	)

func set_rect(_rect: Rect2) -> void:
	self.rect = _rect
	self.pos.x = (rect.position.x + rect.end.x) / 2
	self.pos.y = (rect.position.y + rect.end.y) / 2

func set_type(_type: int) -> void:
	self.type = _type

func merge(cell: DungeonCell) -> bool:
	if !cell:
		return false

	return merge_rect(cell.rect)

func merge_rect(r: Rect2) -> bool:
	var intersects = self.rect.intersects(r, true)
	var rect_eq = Util.rect2_component_equality(self.rect, r)

	# Only merge if cells are aligned on some axis and are at least touching
	if intersects && (rect_eq.y || rect_eq.x):
		set_rect(self.rect.merge(r))
		return true

	return false

func is_typeless() -> bool:
	return self.type == DungeonVariables.CellType.NONE

func is_room() -> bool:
	return self.type == DungeonVariables.CellType.ROOM

func is_sideroom() -> bool:
	return self.type == DungeonVariables.CellType.SIDEROOM

func is_corridor() -> bool:
	return self.type == DungeonVariables.CellType.CORRIDOR
