extends CharacterBody3D
class_name EnemyController

@export var SPEED := 20.0
@export var MAX_SPEED := 80.0 # meters per second
@export var MIN_SPEED := -20.0
@export var acceleration := 0.1
@export var decceleration := 0.5

@export var desired_speed_acceleration := 0.1
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

@onready var outline_mesh: MeshInstance3D = $Bob/Outline
@export var is_outline: bool = false

var is_attacking: bool = false
var empty_array: Array[CharacterBody3D] = []
var selected_enemies_array: Array[CharacterBody3D] = []
@export var max_enemies_lock: int = 1

func _ready() -> void:
	pitch_speed = deg_to_rad(pitch_speed)
	yaw_speed = deg_to_rad(yaw_speed)
	roll_speed = deg_to_rad(roll_speed)
	
func _physics_process(delta: float):
	move_character(delta)

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

func toggle_outline():
	is_outline = not is_outline
	outline_mesh.visible = not outline_mesh.visible

