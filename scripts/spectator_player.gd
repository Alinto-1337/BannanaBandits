extends RigidBody3D

@export var visuals: Node3D
@export_group("Debug")	  
@export var server_can_see_spectators: bool

var lerped_move_input: Vector3
var raw_move_input: Vector3

var current_camera_pitch: float

func _ready() -> void:
	if server_can_see_spectators: 
		visuals.visible = true

func _process(delta: float) -> void:
	
	var target_move_input = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		target_move_input.y -= 1
	if Input.is_action_pressed("move_back"):
		target_move_input.y -= -1
	if Input.is_action_pressed("move_right"):
		target_move_input.x -= -1
	if Input.is_action_pressed("move_left"):
		target_move_input.x -= 1 
	

func rotate_camera(delta: Vector2) -> void:
	
	rotation_degrees.y -= delta.x
	#print(delta)
	current_camera_pitch -= delta.y
	current_camera_pitch = clamp(current_camera_pitch, -90, 90)
	rotation_degrees.x = current_camera_pitch
	
	return

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)
