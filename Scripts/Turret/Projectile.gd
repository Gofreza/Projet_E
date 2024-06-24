#extends RigidBody3D
#
#@export var speed: float = 100.0
#@export var damage: float
#@export var turret_range: float
#var target_enemy: CharacterBody3D
#var target_position: Vector3
#var lifespan: float
#
#@onready var timer: Timer = $Timer
#
#func _ready():
	#if target_enemy:
		#target_position = target_enemy.global_transform.origin
#
	## Calculate the maximum lifespan based on the turret range and speed
	#lifespan = turret_range / speed * 2
	#
	## Start the timer with the calculated lifespan
	#timer.start(lifespan)
	#timer.timeout.connect(_on_Timer_timeout)
	#
	#
#func _integrate_forces(state):
	#var delta = state.get_step()
	#
	#if target_enemy and target_enemy.is_inside_tree():
		#var enemy_direction = (target_position - global_transform.origin).normalized()
		## Calculate the rotation to look at the target
		#look_at(target_position)
		#
		## Move and collide with the calculated direction
		#var collision = move_and_collide(enemy_direction * speed * delta)
		#
		#if collision:
			## Handle collision logic
			#_on_collision(collision.get_collider())
	#
	### Check if the bullet should be freed
	##if global_transform.origin.distance_to(target_position) > turret_range:
		##queue_free()
#
#func _on_collision(body):
	#if body.is_in_group("enemies"):
		#if body.has_method("get_damage"):
			#body.call("get_damage", damage)
		#timer.stop()
		#timer.timeout.disconnect(_on_Timer_timeout)
		#queue_free()
#
#func _on_Timer_timeout():
	#timer.stop()
	#timer.timeout.disconnect(_on_Timer_timeout)
	#queue_free()
extends RigidBody3D

@export var speed: float = 100.0
@export var damage: float
@export var turret_range: float
var projectile_parent
var projectile_origin: Vector3
var direction: Vector3

func _ready():
	gravity_scale = 0
	# Calculate the initial direction based on the cannon's orientation
	var cannon_direction = direction.normalized()
	linear_velocity = cannon_direction * speed  # Set initial velocity
	
func _integrate_forces(state):
	var delta = state.get_step()
	
	var collision = move_and_collide(linear_velocity * delta)
	if collision:
		_on_collision(collision.get_collider())
		
	# Check if the bullet has reached its range
	if global_transform.origin.distance_to(projectile_origin) > turret_range:
		#print(global_transform.origin-projectile_origin)
		queue_free()  # Free the bullet if it exceeds the range

func _on_collision(body):
	if body.is_in_group("enemies"):
		if body.has_method("get_damage"):
			body.call("get_damage", damage, projectile_parent)  # Apply damage to the enemy
		queue_free()  # Destroy the bullet after hitting an enemy
