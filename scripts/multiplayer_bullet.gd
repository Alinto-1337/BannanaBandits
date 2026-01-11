extends Node3D
class_name  MultiplayerBullet

var game_controller: GameController

# Raycast
@export var raycast: RayCast3D
@export var line_renderer: LineRenderer3D
@export var near_range: float
@export var far_range: float

 
var raycast_start_pos: Vector3
var raycast_shoot_direction: Vector3

var _suicide_timer: Timer

var fx_spawner: FXSpawner;

# Line
var line_start_pos: Vector3

func _process(_delta: float) -> void:
	# var t = Time.get_ticks_msec() - start_time
	# global_position = start_pos + start_impulse_direction * t + gravity_factor * Vector3.DOWN
	pass;


func _ready() -> void:
	fx_spawner = FXSpawner.instance;
	game_controller = GameController.instance;
	if game_controller == null:
		printerr("No GameController found in the scene, damage wont work");
	
	var raycast_target := raycast_start_pos - raycast_shoot_direction * far_range;
	
	raycast.global_position = raycast_start_pos - raycast_shoot_direction * near_range;
	raycast.target_position = raycast_target - raycast.global_position;
	
	visible = true;

var gay: bool;
var flag: bool;
func _physics_process(delta: float) -> void:
	if !gay:
		gay = true
		return;
	if flag: return;
	flag = true;
	
	if raycast.is_colliding():
		var ray_hit: Vector3 = raycast.get_collision_point();
		var hit_collider = raycast.get_collider()
		print("colliding with {col}".format({ "col": (hit_collider as Node3D).name }));
		line_renderer.points = [line_start_pos, ray_hit];
		
		fx_spawner.play_vfx("hit_spark", ray_hit, raycast.get_collision_normal(), false)
		
		
		if multiplayer.is_server():  # ----- DAMAGE 
			DebugView.set_value("hit", hit_collider.name)
			if hit_collider is Player3D:
				_deal_damage_to_player(hit_collider);
				fx_spawner.play_sfx("gun_hit_player", ray_hit)
			else:
				fx_spawner.play_sfx("gun_hit", ray_hit)
				fx_spawner.play_vfx("gun_hit_dot", ray_hit)
	else: 
		print("colliding w NATHANG ;-;");
		line_renderer.points = [line_start_pos, raycast.target_position];
	
	
	_suicide_timer = Timer.new();
	_suicide_timer.one_shot = true;
	_suicide_timer.timeout.connect(_commit_suicide)
	add_child(_suicide_timer)
	_suicide_timer.start(0.03);


func _deal_damage_to_player(player: Node3D):
	
	game_controller.server_register_damage_to_peer(int(player.name), "Handy")
	
	pass

func _commit_suicide():
	queue_free()
