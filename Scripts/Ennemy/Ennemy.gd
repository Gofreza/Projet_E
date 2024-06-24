extends CharacterBody3D

signal set_enemy_selected(enemy: Node3D)
signal set_enemy_dead(enemy: Node3D)

@export var health: float = 1000.0 : set = set_health, get = get_health
@export var shield: float = 500.0 : set = set_shield

# Spawn and idle zone
@export var width: int
@export var height: int
@export var spawn_position: Vector3 = Vector3()  # Spawn position

@export var speed: float = 20.0  # Movement speed
@export var wait_time: float = 1.0  # Time to wait before moving again
var target: Vector3 = Vector3()  # Target position

@export var yaw_speed := 45.0 # degrees per second
@export var pitch_speed := 45.0
@export var roll_speed := 55.0

@onready var outline_mesh: MeshInstance3D = $Bob/Outline
@export var is_outline: bool = false
@onready var health_bar_sprite = $HealthBar
@onready var health_bar = $HealthViewPort/HealthBar3D
@onready var shield_bar_sprite = $ShieldBar
@onready var shield_bar = $ShieldViewPort/ShieldBar3D

var is_attacking: bool = false
var attack_range: float
var stop_range: float
var forget_range: float
var selected_enemies_array: Array[CharacterBody3D] = []
var target_enemy: CharacterBody3D
@onready var turret_manager = $TurretManager

enum State {
	MOVING,
	WAITING,
	CHASING,
	ATTACKING,
	RETURNING,
	FLEEING
}

var state: State = State.MOVING

func _ready():
	# Set heatlh and shield bar
	health_bar.max_value = health
	health_bar.value = health
	shield_bar.max_value = shield
	shield_bar.value = shield
	
	# Hide Health and Shield bar
	health_bar_sprite.visible = false
	shield_bar_sprite.visible = false
	
	attack_range = turret_manager.get_range()
	stop_range = attack_range
	forget_range = attack_range*4
	
	# Set an initial random target position
	set_random_target()

# Use _physics_process to use collision
func _physics_process(delta):
	match state:
		State.MOVING:
			#move_towards_target(delta)
			pass
		State.WAITING:
			pass  # Do nothing
		State.CHASING:
			pass
		State.ATTACKING:
			move_towards_target(delta)
			pass
		State.RETURNING:
			move_away_from_target(delta)
		State.FLEEING:
			pass

func idle(delta):
	pass

func move_towards_target(delta):
	if target_enemy:
		target = target_enemy.global_transform.origin  # Update target position dynamically
	
	var new_direction
	var strafe_position
	
	if state == State.ATTACKING:
		# Calculate direction to the target
		var direction = (target - global_transform.origin).normalized()
		
		# Convert the direction to a quaternion
		var target_rotation = Basis().looking_at(direction, Vector3.UP).get_rotation_quaternion()
		
		# Interpolate the current rotation towards the target rotation
		var current_rotation = global_transform.basis.get_rotation_quaternion()
		var new_rotation = current_rotation.slerp(target_rotation, 2 * delta)
		
		# Apply the new rotation
		global_transform.basis = Basis(new_rotation)
		
		var forward_dir = global_transform.basis.z.normalized()
		if direction.dot(forward_dir) > 0.99:  # Aligned threshold
			velocity = -global_transform.basis.z * (speed * 2) * delta  # Charge speed
		else:
			velocity = -global_transform.basis.z * speed * delta
		
		move_and_collide(velocity)
		
		# Check if the enemy has passed the target
		if global_transform.origin.distance_to(target) < 10:
			state = State.RETURNING

	## Move towards the target position
	#var target_direction = (target - global_transform.origin).normalized()
	#new_direction = target_direction
	## Use velocity and move_and_slide to use physics
	#velocity = new_direction * speed * delta
	
	#var collision = move_and_collide(velocity)
	#if global_transform.origin != target:
		#look_at(target)
	
	#if collision:
		#state = State.WAITING
		#wait_before_moving()
	
	#if state == State.CHASING:
		## Check if the target is too far, if it is, get back to waiting
		#
		#if global_transform.origin.distance_to(target) < stop_range:
			#state = State.WAITING
	#elif state == State.ATTACKING:
		#if global_transform.origin.distance_to(target) > attack_range:
			#state = State.CHASING
	#else:
		#if global_transform.origin.distance_to(target) < 1:
			#state = State.WAITING
			#wait_before_moving()

func move_away_from_target(delta):
	# Move away from the target
	velocity = -global_transform.basis.z * speed * delta
	move_and_collide(velocity)
	
	# Check if the enemy is far enough from the target
	if global_transform.origin.distance_to(target) > stop_range * 2:
		state = State.ATTACKING

func _input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Enemy clicked!")
			set_enemy_selected.emit(self.get_parent_node_3d())

func wait_before_moving():
	await get_tree().create_timer(wait_time).timeout
	# Check if a state changement happen
	if state == State.ATTACKING or state == State.CHASING:
		return
	set_random_target()
	state = State.MOVING

func set_random_target():
	# Set a new random target position
	target = spawn_position + Vector3(randi() % width - width/2.0, randi() % width - width/2.0, randi() % height - height/2.0)

func apply_rotation(vector, delta):
	rotate(basis.z, vector.z * roll_speed * delta)
	rotate(basis.x, vector.x * pitch_speed * delta)
	rotate(basis.y, vector.y * yaw_speed * delta)

func toggle_outline():
	is_outline = not is_outline
	outline_mesh.visible = not outline_mesh.visible
	health_bar_sprite.visible = is_outline
	shield_bar_sprite.visible = is_outline

func get_damage(damage: float, target) -> float:
	if !is_attacking:
		target_enemy = target
		is_attacking = true
		state = State.ATTACKING
	if shield > 0:
		# Shield take damage
		shield -= 0.9 * damage
		shield_bar.value -= 0.9 * damage
		health -= 0.1 * damage
		health_bar.value -= 0.1 * damage
	else:
		health -= damage
		health_bar.value -= damage
	if health <= 0:
		# Send signal to enemy manager and the character who kill it
		#target_enemy.get_parent()._on_ennemy_dead(self.get_parent_node_3d())
		#set_enemy_dead.emit(self.get_parent_node_3d())
		pass
		
	return health

func get_health():
	return health

func attack_target():
	# Maybe don't use this to not refresh the target every frame
	if turret_manager.has_method("set_selected_enemies_array"):
		turret_manager.call("set_selected_enemies_array", selected_enemies_array)
	
func set_health(value):
	health = value
	
func set_shield(value):
	shield = value
