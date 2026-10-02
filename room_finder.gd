@tool
extends Node3D

var max_pos: Vector2 = Vector2(0, 0)
var min_pos: Vector2 = Vector2(0, 0)
## x,y = max pos x, z. z,w = minimum pos x, z.
@export var regions: Array[Vector4]
##size of your wall node to avoid clipping etc
@export var wall_size: float = 1.0
## Max size a room can be (1-4)
@export_range(1, 4) var max_room_size: int = 4:
	set(value):
		max_room_size = value
		notify_property_list_changed()
##minimum size room can be chosen to be (will be smaller if unable to find a nearby position to expand to)
@export_range(1, 4) var target_min_room_size: int = 2
@export var spawn_entrance: bool = true:
	set(value):
		spawn_entrance = value
		notify_property_list_changed()
##what wall to place the entrance (has to be on an outer wall of section or will not work, vertical wall has to have the same x coord as the max/min of a given region, horizontal wall has to have the same y axis as the max/ min of a given region)
@export var entrance_pos: Vector2
##h = horizontal wall, v = vertical wall
@export_enum("h", "v") var door_axis: String = "v"
@export var top_down_camera: Camera3D
##node that the walls/doors get added as children under
@export var room_holder: Node3D
var grid_size: Vector2
var free_coords: Array = []
var all_coords: Array
var current_pos = Vector2(1, 1)
var room_starts: Array = []
var rooms: Array = []
var walls: Dictionary = {"h": {"walls": [], "doors": []},"v": {"walls": [], "doors": []}}
var connections: Array = []
var doorpos
@onready var wall = preload("res://Shapes/wall.tscn")
@onready var door = preload("res://Shapes/door.tscn")

signal finished_generating

func _validate_property(property: Dictionary) -> void:
	if property.name == "target_min_room_size":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0,%f,0.1" % max_room_size
	if property.name == "entrance_pos" or property.name == "door_axis":
		if spawn_entrance:
			property.usage |= PROPERTY_USAGE_EDITOR
		else:
			property.usage &= ~PROPERTY_USAGE_EDITOR

func _ready() -> void:
	print(entrance_pos)
	if Engine.is_editor_hint():
		return
	find_free_coords()
	if top_down_camera != null:
		top_down_camera.size = grid_size.y*wall_size + 2
		top_down_camera.position.x = (max_pos.x + min_pos.x)/2 + wall_size
		top_down_camera.position.z = (max_pos.y + min_pos.y)/2 + wall_size
	generate_rooms()
	spawn_walls()
	finished_generating.emit()

func find_free_coords():
	for i in range(regions.size()):
		max_pos.x = regions[i].x if regions[i].x > max_pos.x or i == 0 else max_pos.x
		max_pos.y = regions[i].y if regions[i].y > max_pos.y or i == 0 else max_pos.y
		min_pos.x = regions[i].z if regions[i].z < min_pos.x or i == 0 else min_pos.x
		min_pos.y = regions[i].w if regions[i].w < min_pos.y or i == 0 else min_pos.y
		doorpos = Vector2(regions[i].z, regions[i].w) if regions[i].w < min_pos.y  or i == 0 else doorpos
	grid_size = round((max_pos - min_pos)/wall_size)
	doorpos = round(doorpos - min_pos/wall_size) + Vector2(1, 1)
	free_coords.clear()
	for i in range(regions.size()):
		var region_max: Vector2 = Vector2(regions[i].x, regions[i].y)
		var region_min: Vector2 = Vector2(regions[i].z, regions[i].w)
		var region_size = round((region_max-region_min)/wall_size)
		var offset = region_min - min_pos 
		var grid_offset = round(offset/wall_size)
		for ii in range(region_size.x):
			for iii in range(region_size.y):
				var point = Vector2(ii+1, iii+1) + grid_offset
				if !free_coords.has(point):
					free_coords.append(point)
		if door_axis == "h":
			if region_max.y == entrance_pos.y or region_min.y == entrance_pos.y:
				if entrance_pos.x <= region_max.x and entrance_pos.x >= region_min.x:
					doorpos = round((entrance_pos - min_pos)/wall_size)+ Vector2(1, 1)
		else:
			if region_max.x == entrance_pos.x or region_min.x == entrance_pos.x:
				if entrance_pos.y <= region_max.y and entrance_pos.y >= region_min.y:
					doorpos = round((entrance_pos - min_pos)/wall_size)+ Vector2(1, 1)
	all_coords = free_coords.duplicate()

func generate_rooms():
	while free_coords.size() > 0:
		if !find_free_pos():
			break
		generate_room()

func find_free_pos():
	current_pos = Vector2(1, 1)
	while !free_coords.has(current_pos):
		if current_pos.x == grid_size.x:
			current_pos.x = 0
			current_pos.y += 1
		current_pos.x += 1
		if current_pos == grid_size and !free_coords.has(current_pos):
			return false
	return true

func generate_room():
	var room_size = randi_range(target_min_room_size, max_room_size)
	var current_room: Array = [current_pos]
	room_starts.append(current_pos)
	free_coords.erase(current_pos)
	for i in range(room_size-1):
		var has_chosen: bool = false
		var positions: Array = []
		positions.append(current_pos + Vector2(1, 0))
		positions.append(current_pos + Vector2(-1, 0))
		positions.append(current_pos + Vector2(0, 1))
		positions.append(current_pos + Vector2(0, -1))
		for ii in range(4):
			var npos = positions.pick_random()
			positions.erase(npos)
			if free_coords.has(npos):
				current_pos = npos
				has_chosen = true
				break
		if !has_chosen:
			break
		current_room.append(current_pos)
		free_coords.erase(current_pos)
	rooms.append(current_room)

var selfint = 0
func spawn_walls():
	connections.clear()
	if spawn_entrance:
		walls[door_axis]["doors"].append(doorpos)
	for i in range(rooms.size()):
		selfint = i
		for ii in range(rooms[i].size()):
			find_walls("doors" if room_starts.has(rooms[i][ii]) else "walls", rooms[i][ii], rooms[i], "v", Vector2(1, 0))
			find_walls("doors" if room_starts.has(rooms[i][ii]) else "walls", rooms[i][ii], rooms[i], "h", Vector2(0, 1))
	spawn_part(walls["v"]["doors"], door, 0)
	spawn_part(walls["v"]["walls"], wall, 0)
	spawn_part(walls["h"]["doors"], door, 90)
	spawn_part(walls["h"]["walls"], wall, 90)

func find_walls(type: String, part: Vector2, room: Array, p: String, addition: Vector2):
	var tpos: Vector2 = part + addition
	if !room.has(tpos):
		var forced = true if !all_coords.has(tpos) else false
		add_wall(tpos, p, type, forced)
	tpos = part
	if !room.has(tpos - addition):
		var forced = true if !all_coords.has(tpos-addition) else false
		add_wall(tpos, p, type, forced)

func add_wall(tpos, p, type, forced):
	var next_room = -500
	for i in range(rooms.size()):
		if rooms[i].has(tpos):
			next_room = i
	var _connecting = ""
	if selfint > next_room:
		_connecting = str(next_room) + "-" + str(selfint)
	else:
		_connecting = str(selfint) + "-" + str(next_room)
	if !walls[p]["doors"].has(tpos):
		if walls[p]["walls"].has(tpos):
			walls[p]["walls"].erase(tpos)
		if connections.has(_connecting):
			walls[p]["walls"].append(tpos)
		else:
			connections.append(_connecting)
			if forced:
				walls[p]["walls"].append(tpos)
			else:
				walls[p][type].append(tpos)

func spawn_part(arr: Array, inst, rotset: float):
	for i in range(arr.size()):
		var walli = inst.instantiate()
		var pos = arr[i] * wall_size + min_pos
		room_holder.add_child(walli) 
		walli.global_position = Vector3(pos.x, 0, pos.y)
		walli.global_rotation_degrees.y = rotset
