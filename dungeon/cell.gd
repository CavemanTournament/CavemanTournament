extends RigidBody
class_name DungeonCell

var id: int
var height: float
var rect: = Rect2()
var type: = DungeonVariables.CELL_TYPE_NONE

var collision_shape
var mesh_instance

func _init(_id: int):
	# Set RigidBody mode
	self.mode = MODE_STATIC

	self.id = _id
	self.collision_shape = CollisionShape.new()
	self.mesh_instance = MeshInstance.new()

	var shape = BoxShape.new()
	var mesh = CubeMesh.new()

	self.collision_shape.set_shape(shape)
	self.mesh_instance.set_mesh(mesh)

	add_child(self.collision_shape)
	add_child(self.mesh_instance)

func distance_to(cell: DungeonCell):
	return self.transform.origin.distance_to(cell.transform.origin)

func set_size(size: Vector3):
	self.height = size.y

	var x = self.transform.origin.x - (size.x / 2)
	var z = self.transform.origin.z - (size.z / 2)
	set_rect(Rect2(x, z, size.x, size.z))

	self.collision_shape.shape.extents = size
	self.mesh_instance.mesh.size = size

func get_size():
	return Vector3(self.rect.size.x, self.height, self.rect.size.y)

func move(translation: Vector3):
	set_position(self.transform.origin + translation)

func set_position(pos: Vector3):
	self.transform.origin = pos
	self.rect = Rect2(
		pos.x - (self.rect.size.x / 2),
		pos.z - (self.rect.size.y / 2),
		self.rect.size.x,
		self.rect.size.y
	)

func set_rect(_rect: Rect2):
	self.rect = _rect
	self.transform.origin.x = (rect.position.x + rect.end.x) / 2
	self.transform.origin.z = (rect.position.y + rect.end.y) / 2

func set_type(_type: int):
	self.type = _type
	self.mesh_instance.mesh.set_material(DungeonVariables.CELL_MATERIALS[type])

func merge(cell: DungeonCell):
	if !cell:
		return false

	var intersects = self.rect.intersects(cell.rect, true)
	var rect_eq = Util.rect2_component_equality(self.rect, cell.rect)

	# Only merge if cells are aligned on some axis and are at least touching
	if intersects && (rect_eq.y || rect_eq.x):
		set_rect(self.rect.merge(cell.rect))
		return true

	return false

func is_typeless():
	return self.type == DungeonVariables.CELL_TYPE_NONE

func is_room():
	return self.type == DungeonVariables.CELL_TYPE_ROOM

func is_sideroom():
	return self.type == DungeonVariables.CELL_TYPE_SIDEROOM

func is_corridor():
	return self.type == DungeonVariables.CELL_TYPE_CORRIDOR
