extends CharacterBody3D

const SPEED = 2.0
var in_map: bool = false
@onready var room_finder = $"../.."

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	room_finder.finished_generating.connect(setup)

func setup():
	if room_finder.door_axis == "v":
		$"..".position.x = room_finder.doorpos.x - 1 + room_finder.min_pos.x/room_finder.wall_size
		$"..".position.z = room_finder.doorpos.y + 0.5 + room_finder.min_pos.y/room_finder.wall_size
	else:
		$"..".position.x = room_finder.doorpos.x + 0.5 + room_finder.min_pos.x/room_finder.wall_size
		$"..".position.z = room_finder.doorpos.y -1 + room_finder.min_pos.y/room_finder.wall_size
	$"../../MiniMap/Panel/SubViewportContainer/SubViewport/Camera2D/Area2D/CollisionShape2D".disabled = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !in_map:
		rotate_y(-event.relative.x * 0.005)
		$Camera3D.rotate_x(-event.relative.y * 0.005)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, deg_to_rad(-70), deg_to_rad(70))
	if Input.is_action_just_pressed("ui_cancel"):
		if in_map:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$"../../TopDownCamera".current = false
			$Camera3D.current = true
			$"../../MiniMap".show()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$"../../TopDownCamera".current = true
			$Camera3D.current = false
			$"../../MiniMap".hide()
		in_map = !in_map
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().quit()
