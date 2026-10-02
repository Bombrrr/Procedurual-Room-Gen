extends Node3D

@export var room_finder: Node3D
@export_dir var shape_folder: String
var rooms: Array = []
var shapes: Dictionary = {
	"1": {"O":
		[[Vector2(0, 0)]],
		},
	"2": {"I":
		[[Vector2(0, 0), Vector2(0, 1)]],
		"IH":
		[[Vector2(0, 0), Vector2(1, 0)]]
		},
	"3": {"L":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)], [Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)], [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
		"I":
		[[Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)]],
		"IH":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)]],
		},
	"4": {"O":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]],
		"I":
		[[Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]],
		"IH":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)]],
		"S":
		[[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 2)]],
		"SH":
		[[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(2, 0)]],
		"Z":
		[[Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 2)]],
		"ZH":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)]],
		"L":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)], [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)]],
		"LH":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1)], [Vector2(2, 0), Vector2(2, 1), Vector2(1, 1), Vector2(0, 1)]],
		"RL":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 2)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2)]],
		"RLH":
		[[Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(2, 1)], [Vector2(0, 0), Vector2(2, 1), Vector2(1, 1), Vector2(0, 1)]],
		},
}
var shape_list = []
var offset: Vector2
var wallsize: float
signal shapes_generated

func _ready() -> void:
	room_finder.finished_generating.connect(setup)

func setup():
	offset = room_finder.min_pos
	wallsize = room_finder.wall_size
	rooms = room_finder.rooms
	find_shape()
	spawn_shape()

func find_shape():
	for i in range(rooms.size()):
		var minimums = Vector2(100, 100)
		for ii in range(rooms[i].size()):
			if rooms[i][ii].x < minimums.x:
				minimums.x = rooms[i][ii].x
			if rooms[i][ii].y < minimums.y:
				minimums.y = rooms[i][ii].y
		for shape in shapes[str(rooms[i].size())].keys():
			var has_found = false
			var shape_rot = 0
			for rot in range(shapes[str(rooms[i].size())][shape].size()):
				var is_correct = true
				for part in range(shapes[str(rooms[i].size())][shape][rot].size()):
					if !rooms[i].has(shapes[str(rooms[i].size())][shape][rot][part] + minimums):
						is_correct = false
						break
				if is_correct:
					has_found = true
					shape_rot = 360/shapes[str(rooms[i].size())][shape].size()*rot
					break
			if has_found:
				var shape_data: Dictionary = {
					"size": rooms[i].size(),
					"shape": str(shape),
					"rot": shape_rot,
					"pos": minimums,
				}
				shape_list.append(shape_data)
				break

func spawn_shape():
	for i in range(shape_list.size()):
		var data = shape_list[i]
		var path = shape_folder + "/" + str(data["size"]) + "/" + data["shape"] + ".tscn"
		var shape = load(path)
		var shapi = shape.instantiate()
		$"..".add_child(shapi)
		var pos = data["pos"]
		pos = data["pos"] * wallsize + offset
		shapi.global_position = Vector3(pos.x, 0, pos.y)
		shapi.get_node("rotator").global_rotation_degrees.y = data["rot"]
		shapi.scale = Vector3(1, 1, 1)*wallsize
	shapes_generated.emit()
