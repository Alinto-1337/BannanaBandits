extends Node3D

@export var bullet_scene: PackedScene
@export var fire_cooldown: float
@export var camera_head: Node3D

@export_group("Bullet Settings")
@export var bullet_gravity_factor: float = 1
@export var bullet_speed: float = 5

var _last_gun_fire_time: float

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_pressed("gun_fire") and Time.get_ticks_msec() - _last_gun_fire_time > fire_cooldown:
		_last_gun_fire_time = Time.get_ticks_msec()
		
		if Time.get_ticks_usec() - _last_gun_fire_time > fire_cooldown:
			print("gun_fire")
			fire_bullet.rpc(
				global_position, 
				camera_head.global_basis.z,
				global_position
			);
		

@rpc("authority", "call_local")
func fire_bullet(start_pos: Vector3, shoot_direction: Vector3, line_start_pos: Vector3):
	print("FIRE BULLET RCP");
	
	var bullet: MultiplayerBullet = bullet_scene.instantiate();
	
	bullet.raycast_shoot_direction = shoot_direction;
	bullet.raycast_start_pos = start_pos;
	bullet.line_start_pos = line_start_pos;
	
	get_tree().root.add_child(bullet);
