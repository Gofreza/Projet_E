extends CharacterBody3D
class_name ShipController

@export var SPEED := 20.0
@export var MAX_SPEED := 80.0 # meters per second
@export var MIN_SPEED := -20.0
@export var acceleration := 0.3
@export var decceleration := 1.5

@export var desired_speed_acceleration := 0.5
var desired_speed_forward = 0.0
var desired_speed_strafe = 0.0
var desired_speed_vertical = 0.0

var current_speed_forward = 0.0
var current_speed_strafe = 0.0
var current_speed_vertical = 0.0

var turn_input = Vector2()

@export var yaw_speed := 45.0 # degrees per second
@export var pitch_speed := 45.0
@export var roll_speed := 55.0

@export var health: float = 1000.0
@export var shield: float = 500.0
signal update_health_shield

@onready var turret_manager = $TurretManager
@onready var detection_area = $CameraRoot/CameraYaw/CameraPitch/Camera3D/Area3D

var is_attacking: bool = false
var empty_array: Array[CharacterBody3D] = []
var selected_enemies_array: Array[CharacterBody3D] = []
@export var max_enemies_lock: int = 1

signal fire_cannons_signal
signal lock_enemy_signal
signal unlock_enemy_signal

func _ready() -> void:
	pitch_speed = deg_to_rad(pitch_speed)
	yaw_speed = deg_to_rad(yaw_speed)
	roll_speed = deg_to_rad(roll_speed)
	
	detection_area.locked_enemy_visible.connect(_on_locked_enemy_visible)
	detection_area.locked_enemy_invisible.connect(_on_locked_enemy_invisible)

func _physics_process(delta: float):
	move_character(delta)

func lock_enemy():
	var closest = detection_area.get_closest_enemy_to_cursor()
	if closest:
		closest.toggle_outline()
		if closest.is_outline:
			if selected_enemies_array.size() == max_enemies_lock:
				selected_enemies_array[0].toggle_outline()
				selected_enemies_array.remove_at(0)
			selected_enemies_array.append(closest)
			_on_locked_enemy_visible()
		else:
			selected_enemies_array.erase(closest)
			_on_locked_enemy_invisible()

func move_character(delta):
	# Ship Rotation with turn_input
	var turn_dir = Vector3(turn_input.y, -0, -turn_input.x)
	apply_rotation(turn_dir, delta)
	turn_input = Vector2()

	# Clamp desired speeds to the specified range
	desired_speed_forward = clamp(desired_speed_forward, MIN_SPEED, MAX_SPEED)
	desired_speed_strafe = clamp(desired_speed_strafe, -MAX_SPEED, MAX_SPEED)
	desired_speed_vertical = clamp(desired_speed_vertical, -MAX_SPEED, MAX_SPEED)
	
	# Lerp current speeds towards desired speeds
	current_speed_forward = lerp(current_speed_forward, desired_speed_forward, acceleration * delta if desired_speed_forward > current_speed_forward else decceleration * delta)
	current_speed_strafe = lerp(current_speed_strafe, desired_speed_strafe, acceleration * delta if abs(desired_speed_strafe) > abs(current_speed_strafe) else decceleration * delta)
	current_speed_vertical = lerp(current_speed_vertical, desired_speed_vertical, acceleration * delta if abs(desired_speed_vertical) > abs(current_speed_vertical) else decceleration * delta)

	# Calculate velocity based on current speeds and the ship's orientation
	velocity = -global_transform.basis.z * current_speed_forward
	velocity += global_transform.basis.x * current_speed_strafe
	velocity += global_transform.basis.y * current_speed_vertical

	move_and_slide()

func apply_rotation(vector, delta):
	rotate(basis.z, vector.z * roll_speed * delta)
	rotate(basis.x, vector.x * pitch_speed * delta)
	rotate(basis.y, vector.y * yaw_speed * delta)

func apply_roll(angle):
	rotate(global_transform.basis.y, angle)

func fire_cannons():
	turret_manager.call("fire_cannons")

func get_damage(damage: float) -> float:
	if shield > 0:
		shield -= 0.9 * damage
		health -= 0.1 * damage
	else:
		health -= damage
	if health <= 0:
		print("You are dead")
	
	update_health_shield.emit()
	return health

func _on_locked_enemy_visible():
	turret_manager.call("lock_enemies", selected_enemies_array)

func _on_locked_enemy_invisible():
	turret_manager.call("unlock_enemies")

