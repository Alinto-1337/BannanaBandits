extends CharacterBody3D;
class_name SpectatorPlayer3D;

@export var visuals: Node3D;
@export_group("Movement")
@export var movement_smoothing: float = 0.9;
@export var movement_speed: float = 10;
@export var camera_rotation_stiffness: float = 2;;
@export_group("Debug")
@export var server_can_see_spectators: bool;

var lerped_move_input: Vector3;
var raw_move_input: Vector3;

var target_camera_rotation: Vector3;
var current_camera_rotation: Vector3;

var current_camera_pitch: float;


func _enter_tree() -> void:
	
	set_multiplayer_authority(int(name.erase(0)), true);

func _ready() -> void:
	
	if server_can_see_spectators: 
		visuals.visible = true;
	if not is_multiplayer_authority():
		var cam = $Camera3D as Camera3D;
		cam.queue_free();

func _process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		return;
	
	_update_camera_rotation(delta);
	
	var target_move_input := Vector3.ZERO;
	if Input.is_action_pressed("move_forward"):
		target_move_input.z -= 1;
	if Input.is_action_pressed("move_back"):
		target_move_input.z += 1;
	if Input.is_action_pressed("move_right"):
		target_move_input.x += 1;
	if Input.is_action_pressed("move_left"):
		target_move_input.x -= 1;
	if Input.is_action_pressed("spectator_float_up"):
		target_move_input.y += 1 
	if Input.is_action_pressed("spectator_float_down"):
		target_move_input.y -= 1 
	
	
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	
	DebugView.set_value("movement_inmput", target_move_input)
	raw_move_input = target_move_input.normalized();
	lerped_move_input = lerp(lerped_move_input, raw_move_input, movement_smoothing * delta);
	
	
	velocity = basis * lerped_move_input * movement_speed * delta;
	DebugView.set_value("velocity", velocity);
	
	move_and_slide();

func _update_camera_rotation(delta: float) -> void:
	current_camera_rotation = lerp(current_camera_rotation, target_camera_rotation, camera_rotation_stiffness * delta) as Vector3; 
	# rotate up and down
	rotation_degrees = current_camera_rotation;

func register_camera_rotation_input(delta: Vector2) -> void:
	if (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED): return;
	
	target_camera_rotation -= Vector3(delta.y, delta.x, 0);
	target_camera_rotation.x = clamp(target_camera_rotation.x, -90, 90);

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		register_camera_rotation_input(event.relative);

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
