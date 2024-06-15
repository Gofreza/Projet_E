extends Node3D

var ROTATION_SPEED: float = 5.0
var ELEVATION_SPEED: float = 5.0
@export var max_elevation: float = 90.0
@export var min_elevation: float = 0.0
@export var min_rotation: float = 360.0
@export var max_rotation: float = 360.0
@export var turret_range: float = 100.0
@export var damage: float = 100.0
# Fire rate in seconds
@export var fire_rate: float = 1.0
@onready var turret_base: MeshInstance3D = $TurretBase
@onready var turret: MeshInstance3D = $Turret1Case
@onready var cannon: MeshInstance3D = $Turret1Case/Cannon1
@export var fixed: bool
@export var automatic: bool

var target_enemy: Node3D = null
var can_fire: bool = true
var initial_rotation: Vector3 = Vector3()

@export var texture: CompressedTexture2D
@export var laser_scene: PackedScene
@onready var projectiles_node = get_node("/root/Node3D/Projectiles")

func _ready():
	$Timer.timeout.connect(_on_Timer_timeout)
	$Timer.wait_time = fire_rate
	
	if texture:
		turret_base.material_override = StandardMaterial3D.new()
		turret_base.material_override.albedo_texture = texture
		turret.material_override = StandardMaterial3D.new()
		turret.material_override.albedo_texture = texture
		cannon.material_override = StandardMaterial3D.new()
		cannon.material_override.albedo_texture = texture

func _process(delta):
	#rotate_towards_target(delta)
	if target_enemy:
		rotate_and_elevate(delta, target_enemy.global_position)
		auto_attack_enemy()
	reset_rotation(delta)

func set_target_enemy(enemy):
	target_enemy = enemy

func rotate_and_elevate(delta, target_position):
	if !fixed or (!automatic and is_visible):
		# Code by Neal Holtschulte: https://github.com/nealholt/TurretGodot/tree/main
		# Project the target onto the XZ plane of the turret
		# but first adjust by the global position because
		# the global basis is purely orientation, not position.
		var rotation_targ:Vector3 = get_projected(target_position-turret.global_position, turret.global_basis.y)
		# But! You also need to account for changes in position,
		# so add back in the global position adjustment.
		rotation_targ += turret.global_position
		
		# Get the angle from the body's facing direction (z)
		# to the projected point. Since the point is projected
		# onto the plane, this should be the angle the body
		# should rotate to face along only one axis.
		var y_angle:float = get_angle_to_target(turret.global_position, rotation_targ, turret.global_basis.z)
		# Rotate toward target
		# Calculate sign to rotate left or right.
		var rotation_sign:float = sign(turret.to_local(target_position).x)
		# Calculate step size and direction. Use min to avoid
		# over-rotating. Just snap to the desired angle if it's
		# less than what we would rotate this frame.
		var final_y:float = rotation_sign * min(ROTATION_SPEED * delta, y_angle)
		turret.rotate_y(final_y)
		# Rotation is complete, now we elevate.
		# Project the target onto the ZY plane of the head
		# but first adjust by the global position because
		# the global basis is purely orientation, not position.
		var elevation_targ:Vector3 = get_projected(target_position - cannon.global_position, cannon.global_basis.x)
		# But! You also need to account for changes in position,
		# so add back in the global position adjustment.
		elevation_targ = elevation_targ + cannon.global_position
		
		# Get the angle from the head's facing direction (z)
		# to the projected point. Since the point is projected
		# onto the plane, this should be the angle the head
		# should rotate to face along only one axis.
		var x_angle:float = get_angle_to_target(cannon.global_position, elevation_targ, cannon.global_basis.z)
		
		# Elevate toward target.
		# Calculate sign to elevate up or down.
		# There's an extra negative sign because pitching up is negative.
		var elevation_sign:float = -sign(cannon.to_local(target_position).y)
		# Calculate step size and direction. Use min to avoid
		# over-rotating. Just snap to the desired angle if it's
		# less than what we would rotate this frame.
		var final_x:float = elevation_sign * min(ELEVATION_SPEED * delta, x_angle)
		cannon.rotate_x(final_x)
		# Clamp elevation within limits.
		# Reverse and negate max and min because up is negative and
		# down is positive.
		cannon.rotation.x = clamp(
			cannon.rotation.x,
			-max_elevation, min_elevation
		)
	
func get_angle_to_target(seeker_pos:Vector3, target_pos:Vector3, facing_dir:Vector3) -> float:
	# Pre: target_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# seeker_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# facing_dir is a Vector3 representing the direction
	# we want to find the angle with respect to.
	# Post: Uses Law of Cosines to calculate and
	# return the difference between heading angle
	# (facing_dir) and global angle to target
	# (dir_to) in radians.
	# Typically, facing_dir will be -seeker.global_transform.basis.z
	# but it can be useful to ask about 
	# seeker.global_transform.basis.y to see if target
	# is above or below, or use seeker.global_transform.basis.x
	# to see if target is to the left or right.
	# Return value guaranteed to be between 0 and pi
	var dir_to = seeker_pos.direction_to(target_pos)
	# Normalizing IS necessary under certain circumstances.
	facing_dir = facing_dir.normalized()
	dir_to = dir_to.normalized()
	return acos(facing_dir.dot(dir_to))
	
func get_projected(pos:Vector3, normal:Vector3) -> Vector3:
	normal = normal.normalized()
	var projection:Vector3 = (pos.dot(normal) / normal.dot(normal)) * normal
	return pos - projection

func auto_attack_enemy():
	if target_enemy == null or !can_fire or !target_enemy.is_inside_tree():
		return
		
	# Check if the enemy is in range
	var target_position: Vector3 = target_enemy.get_child(0).global_transform.origin
	var distance_to_enemy = global_transform.origin.distance_to(target_position)
	if distance_to_enemy > turret_range:
		return
	
	# Check if the cannon's elevation angle is clamped at its limits
	if is_cannon_clamped():
		return
	
	fire_laser()
	
	can_fire = false
	$Timer.start(fire_rate)

func fire_laser():
	var laser = laser_scene.instantiate()
	laser.turret_range = turret_range
	laser.damage = damage
	laser.direction = cannon.global_transform.basis.z
	#laser.target_enemy = enemy
	
	if projectiles_node:
		projectiles_node.add_child(laser)
		laser.global_transform.origin = cannon.get_child(0).global_transform.origin
		laser.projectile_origin = laser.global_transform.origin

func reset_rotation(delta):
	if target_enemy == null and !fixed and turret.rotation != initial_rotation or target_enemy != null and !is_visible:
		var current_rotation = turret.rotation.y
		var target_rotation = initial_rotation.y
		var new_rotation = lerp_angle(current_rotation, target_rotation, ROTATION_SPEED * delta)
		turret.rotation.y = new_rotation
		cannon.rotation.x = 0

func _on_Timer_timeout():
	can_fire = true

func lerp_angle(a, b, t):
	var angle = ((b - a + PI) % (2 * PI)) - PI
	return a + angle * t

func rad2deg(radians):
	return radians * 180.0 / PI

func is_cannon_clamped() -> bool:
	var elevation_angle = rad2deg(cannon.rotation.x)
	return elevation_angle <= -max_elevation or elevation_angle >= min_elevation
