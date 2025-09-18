extends CharacterBody3D

@export_category("Movement")
@export var walk_speed: float
@export var sprint_speed: float

@export_category("Camera")
@export var camera_target: Node3D

var move_input: Vector2

var current_camera_pitch: float

#region Entry

func _ready() -> void:
	return


func _process(delta: float) -> void:
	
	return

#endregion

#region Movement

func process_movement() -> void:
	
	return

#endregion

#region Camera

func rotate_camera(delta: Vector2) -> void:
	
	rotation_degrees.y += delta.x
	print(delta)
	current_camera_pitch -= delta.y
	# current_camera_pitch = clamp(current_camera_pitch, 0, 90)
	camera_target.rotate_x(current_camera_pitch)
	
	return

#endregion

#region InputHandeling

func _input(event: InputEvent) -> void:
	var move_input: Vector2
	
	if event.is_action("move_forward"):
		move_input.y += 1
	if event.is_action("move_back"):
		move_input.y += -1
	if event.is_action("move_right"):
		move_input.x += 1
	if event.is_action("move_left"):
		move_input.x += -1
	
	self.move_input = move_input;
	
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)


#endregion
