extends Node3D

@export var bullet_scene: PackedScene
@export var fire_cooldown: float
@export var camera: Node3D
@export var anim_player: AnimationPlayer;


var fx_spawner: FXSpawner;

var _last_gun_fire_time: float

func _ready() -> void:
	fx_spawner = FXSpawner.instance;

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_pressed("gun_fire") and Time.get_ticks_msec() - _last_gun_fire_time > fire_cooldown:
		_last_gun_fire_time = Time.get_ticks_msec()
		
		if Time.get_ticks_usec() - _last_gun_fire_time > fire_cooldown:
			print("gun_fire")
			fire_bullet.rpc(
				camera.global_position, 
				camera.global_basis.z,
				global_position
			);
			#var gay = LineRenderer3D.new()
			#(gay as LineRenderer3D).points = [camera.global_position, camera.global_position-(camera.global_basis.z*20)]
			#get_tree().root.add_child(gay)


@rpc("authority", "call_local", "reliable")
func fire_bullet(start_pos: Vector3, shoot_direction: Vector3, line_start_pos: Vector3):
	print("FIRE BULLET RCP");
	fx_spawner.play_sfx("gun_shot", line_start_pos, randf_range(0.95, 1.05), false)
	fx_spawner.play_vfx("gun_barrel_smoke",  line_start_pos);
	anim_player.play("gun_fire")
	
	var bullet: MultiplayerBullet = bullet_scene.instantiate();
	
	bullet.raycast_start_pos = start_pos;
	bullet.raycast_shoot_direction = shoot_direction;
	bullet.line_start_pos = line_start_pos;
	
	get_tree().root.add_child(bullet);
