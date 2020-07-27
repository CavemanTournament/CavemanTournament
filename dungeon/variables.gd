extends Node

const CELL_TYPE_NONE = 0
const CELL_TYPE_ROOM = 1
const CELL_TYPE_SIDEROOM = 2
const CELL_TYPE_CORRIDOR = 3

const CELL_MATERIALS = [
	null,
	preload("res://dungeon/room.tres"),
	preload("res://dungeon/sideroom.tres"),
	preload("res://dungeon/corridor.tres")
]
