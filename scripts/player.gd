extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float
@export var sprint_speed: float
@export var jump_power: float = 20

@export var gravity: float = -9.8
@export var max_fallspeed: float = 20

@export_group("Camera")
@export var camera_rotation_root: Node3D
@export var smooth_camera: bool = false
@export var camera_rotation_stiffness: float = 2;

var move_input: Vector2
var raw_move_input: Vector2

var target_camera_rotation: Vector3
var current_camera_rotation: Vector3

@export var player_id: int = 1:
	set(id):
		player_id = id
		set_multiplayer_authority(id, true)

#region Entry

func _enter_tree() -> void:
	current_camera_rotation = rotation_degrees
	pass


func _process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		return
	
	process_movement(delta)
	_update_camera_rotation(delta);
	
	if Input.is_action_just_pressed("jump"):
		velocity.y += jump_power
	
	if not is_on_floor():
		#print("is not on floor")
		velocity.y += gravity;
	
	if velocity.y < max_fallspeed:
		velocity.y = max_fallspeed
	
	move_and_slide()
	
	#print(velocity)
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
	
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	raw_move_input = target_move_input.normalized()
	
	move_input = lerp(move_input, raw_move_input, 10 * delta)
	
	var previous_y_velocity = velocity.y
	
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	velocity = Basis(up_direction, rotation.y) * Vector3(move_input.x, 0, move_input.y) * speed
	velocity.y = previous_y_velocity
	return

func _update_camera_rotation(delta: float) -> void:
	current_camera_rotation = lerp(current_camera_rotation, target_camera_rotation, camera_rotation_stiffness * delta) as Vector3 if smooth_camera else target_camera_rotation;
	# rotate up and down
	camera_rotation_root.rotation_degrees.x = current_camera_rotation.x
	# rotate side to side
	rotation_degrees.y = current_camera_rotation.y

#endregion

#region Camera

func register_camera_rotation_input(delta: Vector2) -> void:
	target_camera_rotation -= Vector3(delta.y, delta.x, 0);
	target_camera_rotation.x = clamp(target_camera_rotation.x, -90, 90);

#endregion

#region InputHandeling

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	if event is InputEventMouseMotion:
		register_camera_rotation_input(event.relative)

@rpc("reliable") func init_player():
	position = Vector3(0, 0, 0)  

#endregion
