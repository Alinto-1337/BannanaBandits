extends CharacterBody3D
class_name Player3D

@export_group("Movement")
@export var walk_speed: float
@export var sprint_speed: float
@export var jump_power: float = 20

@export var gravity: float = -9.8
@export var max_fallspeed: float = 20


@export_group("Camera")
@export var camera_rotation_root: Node3D
@export var camera: Camera3D
@export var smooth_camera: bool = false
@export var camera_rotation_stiffness: float = 2;
@export var mouse_sensitivity: float = 0.8;

@export_group("Body")
@export var body_rotation_root: Node3D
@export var body_rotation_degree: float
@export var feet_rotation_root: Node3D
@export var hat: Node3D

@export_group("Crouch")
@export_range(-2, 0, 0.1) var crouch_depth: float = -0.7;
@export var crouch_stiffness: float = 2;
@export var collision_capsule: CollisionShape3D

@export_group("FX")
@export var footstep_audio: AudioStream;
@export var seconds_between_footsteps: float;
@export_range(0, 1, 0.05) var footstep_pitch_random_scale: float = 0.2;
@export var scope_zoom_factor: float = 0.8

@export var spawn_pos: Vector3;

var move_input: Vector2
var raw_move_input: Vector2

var _mouse_delta_sign: Vector2i

var is_running: bool = false;
var last_footstep_time: float;

@export var is_crouching: bool = false;
var current_crouch_level: float;
var start_collision_capsule_height: float;

@export var target_camera_rotation: Vector3
var current_camera_rotation: Vector3
var start_fov: float
var target_fov: float
var start_mouse_sensitivity: float

var fx_spawner: FXSpawner

#region Entry

func _enter_tree() -> void:
	current_camera_rotation = rotation_degrees
	set_multiplayer_authority(int(name.erase(0)), true);
	
	if is_multiplayer_authority():
		
		var spawnpoints = get_tree().get_nodes_in_group("SpawnPoints")
		position = spawnpoints.pick_random().global_position
		
	pass




func _ready() -> void:
	
	
	if is_multiplayer_authority():
		start_fov = camera.fov
		target_fov = start_fov
		start_mouse_sensitivity = mouse_sensitivity;
		hat.visible = false;
		fx_spawner = FXSpawner.instance;
		NetworkManager.print_net(str(get_meta("spawn_pos", "none")))
	else:
		$CameraRoot/HeadNode/Node3D/Camera3D.queue_free();
	
	start_collision_capsule_height = (collision_capsule.shape as CapsuleShape3D).height


func _process(delta: float) -> void:
	
	_update_camera_rotation(delta);
	_update_body_rotation(delta);
	
	var crouch_target
	if is_crouching:
		crouch_target = crouch_depth;
		collision_capsule.scale.y = 0.5;
		collision_capsule.position.y = -(start_collision_capsule_height*0.5*0.5);
	else:
		crouch_target = 0.0;
		collision_capsule.scale.y = 1;
		collision_capsule.position.y = 0;
	
	current_crouch_level = lerp(current_crouch_level, crouch_target, crouch_stiffness*delta)
	body_rotation_root.position.y = current_crouch_level;
	
	if multiplayer.is_server(): _update_footstep_sounds();
	
	if not is_multiplayer_authority():
		return
	
	camera.fov = lerpf(camera.fov, target_fov, 8*delta)
	
	process_movement(delta)
	
	if not is_on_floor():
		#print("is not on floor")
		velocity.y += gravity;
	elif Input.is_action_just_pressed("jump"):
		velocity.y += jump_power
	
	
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
	
	if Input.is_action_just_pressed("scope"):
		target_fov = start_fov * scope_zoom_factor
		mouse_sensitivity = start_mouse_sensitivity*scope_zoom_factor
	elif Input.is_action_just_released("scope"):
		target_fov = start_fov
		mouse_sensitivity = start_mouse_sensitivity
	
	if Input.is_action_just_pressed("crouch"):
		is_crouching = true;
	elif Input.is_action_just_released("crouch"):
		is_crouching = false;
	
	
	
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

	camera_rotation_root.rotation_degrees.y = current_camera_rotation.y
	
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
		feet_rotation_root.rotation_degrees.y = body_rotation_root.rotation_degrees.y;
		pass
	
	pass

#endregion

#region Camera

func register_camera_rotation_input(delta: Vector2) -> void:
	if (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED): return
	
	_mouse_delta_sign = Vector2i(sign(delta.x), sign(delta.y))
	target_camera_rotation -= Vector3(delta.y, delta.x, 0) * mouse_sensitivity;
	target_camera_rotation.x = clamp(target_camera_rotation.x, -90, 90);

#endregion

#region SFX

func _update_footstep_sounds(): 
	if not is_running: return;
	
	var current_time = Time.get_ticks_usec();
	if current_time - last_footstep_time >= seconds_between_footsteps:
		last_footstep_time = current_time;
		
		fx_spawner.play_sfx("footstep", feet_rotation_root.global_position, randf_range(1-footstep_pitch_random_scale, 1+footstep_pitch_random_scale), true)



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
