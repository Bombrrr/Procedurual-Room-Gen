extends CanvasLayer
@export var player: CharacterBody3D
@export var room_finder: Node3D
@export var shape_finder: Node3D
@export var shape_holder: Node2D
@export var player_area: Area2D
@export var discovering_map: bool = false
@export_dir var shape_folder: String

var shape_list = []
var offsets: Vector2
var wallsize: float
var room_color = preload("res://2dShapes/minimap_color.tres")
var current_room_color = preload("res://2dShapes/minimap_color_bright.tres")
var hidden_room_color = preload("res://2dShapes/minimap_color_hidden.tres")

func _ready() -> void:
	shape_finder.shapes_generated.connect(spawn_minimap)
	player_area.area_entered.connect(enter_room)
	player_area.area_exited.connect(leave_room)

func _process(_delta: float) -> void:
	shape_holder.global_position.x = player.global_position.x * 50
	shape_holder.global_position.y = player.global_position.z * 50

func spawn_minimap():
	shape_list = shape_finder.shape_list
	offsets = shape_finder.offset
	wallsize = shape_finder.wallsize
	for i in range(shape_list.size()):
		var data = shape_list[i]
		var path = shape_folder + "/" + str(data["size"]) + "/" + data["shape"] + ".tscn"
		if FileAccess.file_exists(path):
			var shape = load(path)
			var shapi = shape.instantiate()
			shape_holder.add_child(shapi)
			var pos = data["pos"]
			pos = data["pos"] * wallsize + offsets
			shapi.global_position = Vector2(0, 0) - pos * 50
			shapi.get_node("rotator").global_rotation_degrees = 0 - data["rot"]
			shapi.scale = Vector2(1, 1)*wallsize * 50
			if discovering_map:
				for child in shapi.get_node("rotator").get_children():
					if child is MeshInstance2D:
						child.texture = hidden_room_color
	
	var connector = load(shape_folder + "/connector.tscn")
	var doors = room_finder.walls["v"]["doors"]
	for i in range(doors.size()):
		var coni = connector.instantiate()
		var pos = doors[i] * wallsize + offsets
		shape_holder.add_child(coni)
		coni.global_position = Vector2(0, 0) - pos * 50
		coni.scale = Vector2(1, 1)*wallsize * 50
		if discovering_map:
			coni.get_node("MeshInstance2D").texture = hidden_room_color
	doors = room_finder.walls["h"]["doors"]
	for i in range(doors.size()):
		var coni = connector.instantiate()
		var pos = doors[i] * wallsize + offsets
		shape_holder.add_child(coni)
		coni.global_position = Vector2(0, 0) - pos * 50
		coni.scale = Vector2(1, 1)*wallsize * 50
		coni.global_rotation_degrees = -90
		if discovering_map:
			coni.get_node("MeshInstance2D").texture = hidden_room_color

func enter_room(area: Area2D) -> void:
	for child in area.get_parent().get_children():
		if child is MeshInstance2D:
			child.texture = current_room_color

func leave_room(area: Area2D) -> void:
	for child in area.get_parent().get_children():
		if child is MeshInstance2D:
			child.texture = room_color
