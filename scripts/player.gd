extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float
@export var sprint_speed: float
@export var jump_power: float = 20

@export var gravity: float = -9.8
@export var max_fallspeed: float = 20

@export_group("Camera")
@export var camera_target: Node3D

var move_input: Vector2
var raw_move_input: Vector2

var current_camera_pitch: float

#region Entry

func _ready() -> void:
	if not is_multiplayer_authority():
		camera_target.queue_free()


func _process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		return
	
	process_movement(delta)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y += jump_power
	
	if not is_on_floor():
		print("is not on floor")
		velocity.y += gravity;
	
	if velocity.y < max_fallspeed:
		velocity.y = max_fallspeed
	
	move_and_slide()
	
	print(velocity)
	return

#endregion

#region Movement

func process_movement(delta: float) -> void:
	
	var target_move_input = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		target_move_input.y -= 1
	if Input.is_action_pressed("move_back"):
		target_move_input.y -= -1
	if Input.is_action_pressed("move_right"):
		target_move_input.x -= -1
	if Input.is_action_pressed("move_left"):
		target_move_input.x -= 1 
		
	raw_move_input = target_move_input.normalized()
	
	move_input = lerp(move_input, raw_move_input, 10 * delta)
	
	var previous_y_velocity = velocity.y
	
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	velocity = Basis(up_direction, rotation.y) * Vector3(move_input.x, 0, move_input.y) * speed
	velocity.y = previous_y_velocity
	return

#endregion

#region Camera

func rotate_camera(delta: Vector2) -> void:
	
	rotation_degrees.y -= delta.x
	#print(delta)
	current_camera_pitch -= delta.y
	current_camera_pitch = clamp(current_camera_pitch, -90, 90)
	camera_target.rotation_degrees.x = current_camera_pitch
	
	return

#endregion

#region InputHandeling

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)


#endregion
