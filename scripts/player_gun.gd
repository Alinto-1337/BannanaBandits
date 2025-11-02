extends Node3D

@export var bullet_scene: PackedScene
@export var fire_cooldown: float

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
				_last_gun_fire_time, 
				global_position, 
				global_basis * Vector3.FORWARD * bullet_speed, 
				bullet_gravity_factor
			);
		

@rpc("authority", "call_local")
func fire_bullet(start_time:float, start_pos: Vector3, impulse_direction: Vector3, gravity_factor: float):
	print("FIRE BULLET RCP")
	var bullet: MultiplayerBullet = bullet_scene.instantiate()
	bullet.start_time = start_time
	bullet.position = start_pos
	bullet.start_pos = start_pos
	bullet.start_impulse_direction = impulse_direction
	bullet.gravity_factor = gravity_factor
	
	get_tree().root.add_child(bullet);
