extends CharacterBody3D

signal set_enemy_selected(enemy: Node3D)
signal set_enemy_dead(enemy: Node3D)

@export var health: float = 1000.0 : set = set_health, get = get_health
@export var shield: float = 500.0 : set = set_shield

@export var width: int
@export var height: int
@export var spawn_position: Vector3 = Vector3()  # Spawn position

@export var speed: float = 20.0  # Movement speed
@export var wait_time: float = 1.0  # Time to wait before moving again
var target: Vector3 = Vector3()  # Target position

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
var selected_enemies_array: Array[Node3D] = []
var target_enemy: CharacterBody3D
@onready var turret_manager = $TurretManager

enum State {
	MOVING,
	WAITING,
	ATTACKING_AND_MOVING,
	ATTACKING
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
			move_towards_target(delta)
			pass
		State.WAITING:
			pass  # Do nothing
		State.ATTACKING_AND_MOVING:
			#move_towards_target(delta)
			#if global_transform.origin.distance_to(target) >= forget_range:
				#state = State.MOVING
				#selected_enemies_array.clear()
				#target_enemy = null
				#is_attacking = false
				#attack_target()
			#if global_transform.origin.distance_to(target) <= stop_range:
				#state = State.ATTACKING
			pass
		State.ATTACKING:
			#attack_target()
			#if global_transform.origin.distance_to(target_enemy.global_transform.origin) > attack_range:
				#state = State.ATTACKING_AND_MOVING
			pass

func move_towards_target(delta):
	if target_enemy:
		target = target_enemy.global_transform.origin  # Update target position dynamically
	
	# Move towards the target position
	var direction = (target - global_transform.origin).normalized()
	# Use velocity and move_and_slide to use physics
	velocity = direction * speed * delta
	var collision = move_and_collide(velocity)
	if global_transform.origin != target:
		look_at(target)
	
	if collision:
		state = State.WAITING
		wait_before_moving()
	
	if state == State.ATTACKING_AND_MOVING:
		# Check if the target is too far, if it is, get back to waiting
		
		if global_transform.origin.distance_to(target) < stop_range:
			state = State.ATTACKING
	elif state == State.ATTACKING:
		if global_transform.origin.distance_to(target) > attack_range:
			state = State.ATTACKING_AND_MOVING
	else:
		if global_transform.origin.distance_to(target) < 1:
			state = State.WAITING
			wait_before_moving()

func _input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Enemy clicked!")
			set_enemy_selected.emit(self.get_parent_node_3d())

func wait_before_moving():
	await get_tree().create_timer(wait_time).timeout
	# Check if a state changement happen
	if state == State.ATTACKING or state == State.ATTACKING_AND_MOVING:
		return
	set_random_target()
	state = State.MOVING

func set_random_target():
	# Set a new random target position
	target = spawn_position + Vector3(randi() % width - width/2.0, randi() % width - width/2.0, randi() % height - height/2.0)

func find_node_by_name(parent: Node, target_name: String) -> Node:
	for child in parent.get_children():
		if child.name == target_name:
			return child
		var result = find_node_by_name(child, target_name)
		if result:
			return result
	return null

func toggle_outline():
	is_outline = not is_outline
	outline_mesh.visible = not outline_mesh.visible
	health_bar_sprite.visible = is_outline
	shield_bar_sprite.visible = is_outline

func get_damage(damage: float) -> float:
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
		target_enemy.get_parent()._on_ennemy_dead(self.get_parent_node_3d())
		set_enemy_dead.emit(self.get_parent_node_3d())
	
	return health

func get_health():
	return health

func attack_target():
	# Maybe don't use this to not refresh the target every frame
	if turret_manager.has_method("set_selected_enemies_array"):
		turret_manager.call("set_selected_enemies_array", selected_enemies_array)

func set_health(value):
	pass
	
func set_shield(value):
	pass
