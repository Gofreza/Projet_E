extends EnemyController

var target_enemy: CharacterBody3D

enum State {
	MOVING,
	WAITING,
	CHASING,
	ATTACKING,
	AVOIDING,
	RETURNING,
	FLEEING
}

var state: State = State.MOVING
var retreat_distance: float = 100.0
var attack_distance: float = 20.0
var avoid_distance: float = 15.0
var turning_slowdown_factor: float = 0.1

var target_speed_forward: float

func _ready() -> void:
	super._ready()
	set_process(true)

func _process(delta: float) -> void:
	# AI logic to set desired speeds and turn_input
	match state:
		State.MOVING:
			move_to_target(delta)
		State.CHASING:
			chase_target(delta)
		State.ATTACKING:
			attack_target(delta)
		State.AVOIDING:
			avoid_collision(delta)
		State.RETURNING:
			retreat(delta)

	super._physics_process(delta)

func move_to_target(delta: float) -> void:
	if target_enemy:
		var direction = (target_enemy.global_transform.origin - global_transform.origin).normalized()
		turn_towards(direction, delta)
		if (global_transform.origin.distance_to(target_enemy.global_transform.origin) <= attack_distance):
			state = State.ATTACKING
		else:
			target_speed_forward = MAX_SPEED * 0.5
			current_speed_forward = lerp(current_speed_forward, target_speed_forward, delta * acceleration)
			desired_speed_forward = current_speed_forward

func chase_target(delta: float) -> void:
	if target_enemy:
		var direction = (target_enemy.global_transform.origin - global_transform.origin).normalized()
		turn_towards(direction, delta)
		target_speed_forward = MAX_SPEED
		current_speed_forward = lerp(current_speed_forward, target_speed_forward, delta * acceleration)
		desired_speed_forward = current_speed_forward
		if global_transform.origin.distance_to(target_enemy.global_transform.origin) <= attack_distance:
			state = State.ATTACKING

func attack_target(delta: float) -> void:
	if target_enemy:
		#fire_cannons()
		var distance = global_transform.origin.distance_to(target_enemy.global_transform.origin)
		if distance < avoid_distance:
			state = State.AVOIDING
		elif distance > retreat_distance:
			state = State.RETURNING
		else:
			var direction = (target_enemy.position - global_transform.origin).normalized()
			turn_towards(direction, delta)
		
		var target_speed = lerp(0.0, MAX_SPEED * 0.75, distance / retreat_distance)
		target_speed_forward = lerp(current_speed_forward, target_speed, delta * acceleration)
		current_speed_forward = target_speed_forward
		desired_speed_forward = current_speed_forward

func avoid_collision(delta: float) -> void:
	#TODO Instead of backing of, just avoid the target and continue in the same direction
	#TODO At the end, flip over to turn around and charge again 
	if target_enemy:
		var direction = (global_transform.origin - target_enemy.global_transform.origin).normalized()
		turn_towards(direction, delta)
		target_speed_forward = MAX_SPEED * 0.5
		current_speed_forward = lerp(current_speed_forward, target_speed_forward, delta * acceleration)
		desired_speed_forward = current_speed_forward

		if global_transform.origin.distance_to(target_enemy.global_transform.origin) > avoid_distance * 2:
			# Flip over to turn around and then attack again
			state = State.RETURNING

func retreat(delta: float) -> void:
	if target_enemy:
		var direction = (global_transform.origin - target_enemy.global_transform.origin).normalized()
		turn_towards(direction, delta)
		target_speed_forward = MAX_SPEED * 0.5
		current_speed_forward = lerp(current_speed_forward, target_speed_forward, delta * acceleration)
		desired_speed_forward = current_speed_forward

		if global_transform.origin.distance_to(target_enemy.global_transform.origin) > retreat_distance:
			state = State.MOVING

func turn_towards(direction: Vector3, delta: float) -> void:
	# Turn toward the target
	var target_rotation = Basis().looking_at(direction, Vector3.UP).get_rotation_quaternion()
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	var angle_diff = current_rotation.angle_to(target_rotation)

	# Reduce speed when turning significantly
	if angle_diff > 0.1:  # Threshold for significant turn
		print("ji")
		target_speed_forward *= turning_slowdown_factor

	var new_rotation = current_rotation.slerp(target_rotation, 2 * delta)
	global_transform.basis = Basis(new_rotation)

func get_damage(damage: float, target) -> float:
	if !is_attacking:
		target_enemy = target
		is_attacking = true
		state = State.ATTACKING
	if shield > 0:
		# Shield take damage
		shield -= 0.9 * damage
		health -= 0.1 * damage
	else:
		health -= damage
	if health <= 0:
		# Send signal to enemy manager and the character who kill it
		#target_enemy.get_parent()._on_ennemy_dead(self.get_parent_node_3d())
		#set_enemy_dead.emit(self.get_parent_node_3d())
		pass
		
	return health
