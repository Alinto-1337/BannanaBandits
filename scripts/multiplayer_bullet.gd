extends Node3D
class_name  MultiplayerBullet

var camera_root: Node3D

# Raycast
@export var raycast: RayCast3D
@export var line_renderer: LineRenderer3D
@export var near_range: float
@export var far_range: float
 
var raycast_start_pos: Vector3
var raycast_shoot_direction: Vector3

var _suicide_timer: Timer

# Line
var line_start_pos: Vector3

func _process(_delta: float) -> void:
	
	# var t = Time.get_ticks_msec() - start_time
	
	# global_position = start_pos + start_impulse_direction * t + gravity_factor * Vector3.DOWN
	
	
	pass


func _ready() -> void:
	
	var raycast_target := raycast_start_pos - raycast_shoot_direction * far_range;
	
	raycast.position = raycast_start_pos - raycast_shoot_direction * near_range;
	raycast.target_position = raycast_target;
	
	if raycast.is_colliding():
		print("colliding with {col}".format({ "col": (raycast.get_collider() as Node3D).name }));
		line_renderer.points = [line_start_pos, raycast.get_collision_point()];
	else: 
		print("colliding w NATHANG ;-;");
		line_renderer.points = [line_start_pos, raycast_target];
	
	
	_suicide_timer = Timer.new();
	_suicide_timer.one_shot = true;
	_suicide_timer.timeout.connect(_commit_suicide)
	add_child(_suicide_timer)
	_suicide_timer.start(0.1);
	
	
	pass

func _commit_suicide():
	queue_free()
