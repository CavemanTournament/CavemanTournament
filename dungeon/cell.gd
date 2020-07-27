extends RigidBody
class_name DungeonCell

var id: int
var height: int
var rect: = Rect2()
var type: = DungeonVariables.CELL_TYPE_NONE

var collision_shape
var mesh_instance

func _init(_id):
	# Set RigidBody mode
	mode = MODE_STATIC

	id = _id
	collision_shape = CollisionShape.new()
	mesh_instance = MeshInstance.new()

	var shape = BoxShape.new()
	var mesh = CubeMesh.new()

	collision_shape.set_shape(shape)
	mesh_instance.set_mesh(mesh)

	add_child(collision_shape)
	add_child(mesh_instance)

func distance_to(_cell):
	return transform.origin.distance_to(_cell.transform.origin)

func set_size(_size):
	height = _size.y

	var x = transform.origin.x - (_size.x / 2)
	var z = transform.origin.z - (_size.z / 2)
	set_rect(Rect2(x, z, _size.x, _size.z))

	collision_shape.shape.extents = _size
	mesh_instance.mesh.size = _size

func get_size():
	return Vector3(rect.size.x, height, rect.size.y)

func move(_translation):
	set_position(transform.origin + _translation)

func set_position(_pos):
	transform.origin = _pos
	rect = Rect2(_pos.x - (rect.size.x / 2), _pos.z - (rect.size.y / 2), rect.size.x, rect.size.y)

func set_rect(_rect):
	rect = _rect
	transform.origin.x = (rect.position.x + rect.end.x) / 2
	transform.origin.z = (rect.position.y + rect.end.y) / 2

func set_type(_type: int):
	type = _type
	mesh_instance.mesh.set_material(DungeonVariables.CELL_MATERIALS[_type])
