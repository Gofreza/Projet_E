extends Node3D

var parent
@export var selected_enemies_array: Array[CharacterBody3D] = []
@export var is_enemy: bool

var turrets_array: Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	turrets_array = get_children()

func send_to_turrets():
	var enemies_number: int = selected_enemies_array.size()
	var turrets_number: int = turrets_array.size()

	# If there are no enemies, clear all turret targets
	if enemies_number == 0:
		for turret in turrets_array:
			if turret.has_method("set_target_enemy"):
				turret.call("set_target_enemy", null)
		return

	# Distribute enemies to turrets
	for i in range(0, turrets_number):
		var enemy_index = i % enemies_number  # Cycle through enemies
		if turrets_array[i].has_method("set_target_enemy"):
			turrets_array[i].call("set_target_enemy", selected_enemies_array[enemy_index])

# Precise to the turrets that this enemy is dead
func on_enemy_dead(enemy: Node3D):
	var turrets_number: int = turrets_array.size()
	for i in range(turrets_number):
		turrets_array[i].call("on_enemy_dead", enemy)

func set_selected_enemies_array(array: Array[CharacterBody3D]):
	selected_enemies_array.clear()
	selected_enemies_array.append_array(array) 
	send_to_turrets()
	if not is_enemy:
		print("Selected enemies array updated:", selected_enemies_array)

func lock_enemies(array: Array[CharacterBody3D]):
	selected_enemies_array.clear()
	selected_enemies_array.append_array(array) 
	for i in range(turrets_array.size()):
		send_to_turrets()
		turrets_array[i].is_visible = true

func unlock_enemies():
	for i in range(turrets_array.size()):
		turrets_array[i].is_visible = false

func fire_cannons():
	for i in range(turrets_array.size()):
		if !turrets_array[i].automatic:
			turrets_array[i].call("attack_enemy")

func get_range() -> int:
	var turret_range: int = 0
	for i in range(0, turrets_array.size()):
		if turrets_array[i].turret_range > turret_range:
			turret_range = turrets_array[i].turret_range
		
	return turret_range
