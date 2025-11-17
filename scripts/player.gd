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

@export_group("Body")
@export var body_rotation_root: Node3D
@export var body_rotation_degree: float

var move_input: Vector2
var raw_move_input: Vector2

var _mouse_delta_sign: Vector2i

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
	_update_body_rotation(delta);
	
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
	
	velocity = Basis(up_direction, camera_rotation_root.global_rotation.y) * Vector3(move_input.x, 0, move_input.y) * speed
	velocity.y = previous_y_velocity
	return

func _update_camera_rotation(delta: float) -> void:
	current_camera_rotation = lerp(current_camera_rotation, target_camera_rotation, camera_rotation_stiffness * delta) as Vector3 if smooth_camera else target_camera_rotation;
	# rotate up and down
	camera_rotation_root.rotation_degrees.x = current_camera_rotation.x

	camera_rotation_root.rotation_degrees.y = target_camera_rotation.y
	
	#var head_body_angle_diff = camera_rotation_root.global_rotation_degrees.y - global_rotation_degrees.y
	#head_body_angle_diff = min(head_body_angle_diff, 360 - head_body_angle_diff)
	#var camera_body_strain_sign: int = sign(head_body_angle_diff)
	#DebugView.set_value("current_camera_rotation.y", current_camera_rotation.y)
	#DebugView.set_value("camera/body_angle_diff", head_body_angle_diff)
	#DebugView.set_value("Mouse_Delta_Sign", _mouse_delta_sign)
	#DebugView.set_value("BODY_global_rotation_degrees", global_rotation_degrees.y)
	#DebugView.set_value("CAMERA_global_rotation_degrees", camera_rotation_root.global_rotation_degrees.y)
	#DebugView.set_value("camera_body_strain_sign", camera_body_strain_sign)
	#if (abs(head_body_angle_diff) > body_rotation_degree and _mouse_delta_sign.x != camera_body_strain_sign): # camera is pushing against the neck turniong degrees, pull body with it
		#
		#rotation_degrees.y = target_camera_rotation.y + body_rotation_degree * -camera_body_strain_sign
	#else: # camera is within the neck tuning raduis body_rotation_degree
		#camera_rotation_root.rotation_degrees.y = target_camera_rotation.y - rotation_degrees.y

func _update_body_rotation(delta: float) -> void:
	
	# make it clamp to the camera
	var my_camera_root_uvec = Vector3(camera_rotation_root.basis.z.x, 0, camera_rotation_root.basis.z.z).normalized()
	var cam_to_body_rot_diff = rad_to_deg((-my_camera_root_uvec).signed_angle_to(-body_rotation_root.basis.z, body_rotation_root.basis.y))
	
	DebugView.set_value("diff", cam_to_body_rot_diff)
	
	if abs(cam_to_body_rot_diff) > body_rotation_degree:
		
		body_rotation_root.rotation_degrees.y -= cam_to_body_rot_diff - body_rotation_degree * sign(cam_to_body_rot_diff)
		
		pass
	
	pass

#endregion

#region Camera

func register_camera_rotation_input(delta: Vector2) -> void:
	
	_mouse_delta_sign = Vector2i(sign(delta.x), sign(delta.y))
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
