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
@onready var cannon: MeshInstance3D = $Cannon1
@export var fixed: bool
var automatic: bool = false

var can_fire: bool = true
var initial_rotation: Vector3 = Vector3()

@export var texture: CompressedTexture2D
@export var laser_scene: PackedScene
@onready var projectiles_node = get_node("/root/Node3D/Projectiles")

func _ready():
	$Timer.timeout.connect(_on_Timer_timeout)
	$Timer.wait_time = fire_rate
	
	if texture:
		cannon.material_override = StandardMaterial3D.new()
		cannon.material_override.albedo_texture = texture

func attack_enemy():
	if !can_fire:
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

func _on_Timer_timeout():
	can_fire = true

func lerp_angle(a, b, t):
	var angle = ((b - a + PI) % (2 * PI)) - PI
	return a + angle * t

func rad2deg(radians):
	return radians * 180.0 / PI
