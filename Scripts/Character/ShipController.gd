extends Node

const ZOOM_SENSITIVITY = 1.0  # zooming speed
const MIN_ZOOM_DISTANCE = 30.0  # minimum distance from the character
const MAX_ZOOM_DISTANCE = 100.0  # maximum distance from the character

var target_position: Vector3
var move_speed: float = 50.0
var stop_threshold: float = 1.0  # Distance threshold to stop movement

@export var character: Node3D
var character_body 
var turret_manager
@export var camera_root: Node3D
var yaw_node 
var pitch_node
var camera

var is_attacking: bool = false
var empty_array: Array[Node3D] = []
var selected_enemies_array: Array[Node3D] = []

@export var health: float = 10000.0
@export var shield: float = 1000.0
var health_bar_sprite
var health_bar 
var shield_bar_sprite 
var shield_bar 
var isMoving : bool

func _ready():
	character_body = character.get_child(0)
	turret_manager = character_body.get_node("TurretManager")
	turret_manager.parent = self
	yaw_node = camera_root.get_child(0)
	pitch_node = yaw_node.get_child(0)
	camera = pitch_node.get_child(0)
	
	# Get components
	health_bar_sprite = character_body.get_node("HealthBar")
	shield_bar_sprite = character_body.get_node("ShieldBar")
	health_bar = character_body.get_node("HealthViewPort/HealthBar3D")
	shield_bar = character_body.get_node("ShieldViewPort/ShieldBar3D")
	
	# Set heatlh and shield bar
	health_bar.max_value = health
	health_bar.value = health
	shield_bar.max_value = shield
	shield_bar.value = shield
	isMoving = true
	target_position = character_body.global_transform.origin

func _process(delta):
	if isMoving:
		# Update target position if the left mouse button is pressed
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_target_position()
		
		# Move the character towards the target position
		move_character(delta)

func _input(event):
	# Attack selected enemies
	if Input.is_action_just_pressed("jump"):
		attack_selected_enemies()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-ZOOM_SENSITIVITY)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(ZOOM_SENSITIVITY)
	elif event is InputEventPanGesture:
		# Zoom using trackpad pinch gesture
		zoom_camera(event.delta.y * ZOOM_SENSITIVITY)

func update_target_position():
	# Get the camera
	var camera = get_viewport().get_camera_3d()
	
	# Get the current mouse position
	var mouse_position = get_viewport().get_mouse_position()
	
	# Perform a raycast from the camera using the mouse position
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	
	# Calculate the intersection with the XZ plane (assuming y = 0 for ground level)
	var intersection = ray_origin + ray_direction * ((-ray_origin.y) / ray_direction.y)
	target_position = Vector3(intersection.x, character_body.global_transform.origin.y, intersection.z)

func move_character(delta):
	var distance_to_target = character_body.global_transform.origin.distance_to(target_position)
	
	# Move towards the target position if not within the stop threshold
	if distance_to_target > stop_threshold:
		var direction = (target_position - character_body.global_transform.origin).normalized()
		character_body.velocity = direction * move_speed
		character_body.move_and_slide()

		# Rotate character to face the target direction
		character_body.look_at(target_position)
		# Only rotate CollisionShape3D around the Y-axis
		var look_at_y_rotation = (character_body.get_node("CollisionShape3D").global_transform.origin - target_position).normalized()
		look_at_y_rotation.y = 0  # Reset Y component to zero to avoid tilting
		character_body.get_node("CollisionShape3D").look_at(character_body.get_node("CollisionShape3D").global_transform.origin + look_at_y_rotation, Vector3.UP)
	
		# Also move camera
		var camera_target_position = character_body.global_transform.origin + Vector3(0, camera.position.y, 0)
		camera.global_transform.origin = camera_target_position

	else:
		character_body.velocity = Vector3.ZERO  # Stop the character when close to the target

func zoom_camera(amount):
	# Calculate the direction from the camera to the character
	var direction = (character_body.global_transform.origin - camera.global_transform.origin).normalized()
	# Calculate the new distance
	var distance = (camera.global_transform.origin.distance_to(character_body.global_transform.origin)) + amount
	# Clamp the distance
	distance = clamp(distance, MIN_ZOOM_DISTANCE, MAX_ZOOM_DISTANCE)
	# Set the new camera position
	camera.global_transform.origin = character_body.global_transform.origin - direction * distance

func attack_selected_enemies():
	if turret_manager.has_method("set_selected_enemies_array"):
		if is_attacking:
			turret_manager.call("set_selected_enemies_array", empty_array)
			is_attacking = false
		else:
			turret_manager.call("set_selected_enemies_array", selected_enemies_array)
			is_attacking = true

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
		print("You are dead")
	
	return health

func _on_enemy_selected(selected_enemy: Node3D):		
	if selected_enemy.get_child(0).is_outline:
		if selected_enemies_array.has(selected_enemy):
			# Deselect the previously selected enemy (optional)
			selected_enemies_array.remove_at(selected_enemies_array.find(selected_enemy))
			if selected_enemy.get_child(0).health <= 0:
				print(selected_enemy, " died")
				attack_selected_enemies()
				return
	else:
		# Select the new enemy
		selected_enemies_array.append(selected_enemy)
		
	# If too much enemies selected
	# Unselect the first one selected
	if selected_enemies_array.size() > turret_manager.turrets_array.size():
		selected_enemies_array[0].get_child(0).toggle_outline()
		selected_enemies_array.remove_at(0)
		
	# Not moving 
	isMoving = false
	# Set a timer to reset the isMoving flag
	await get_tree().create_timer(0.1).timeout
	isMoving = true

func _on_ennemy_dead(enemy: Node3D):
	if selected_enemies_array.find(enemy) != -1:
		selected_enemies_array.remove_at(selected_enemies_array.find(enemy))
		if selected_enemies_array.size() == 0:
			is_attacking = false

		print("enemy dead")
		turret_manager.call("on_enemy_dead", enemy)
		turret_manager.call("set_selected_enemies_array", selected_enemies_array)
