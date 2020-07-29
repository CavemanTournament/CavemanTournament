extends Node

enum CellType {
	NONE = 0,
	ROOM = 1,
	SIDEROOM = 2,
	CORRIDOR = 3
}

const CELL_MATERIALS = [
	null,
	preload("res://dungeon/room.tres"),
	preload("res://dungeon/sideroom.tres"),
	preload("res://dungeon/corridor.tres")
]
