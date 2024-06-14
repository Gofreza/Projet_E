extends Node

@export var little_ennemy_path: String
var ennemy_array: Array[Node3D]

@export var label : Label
var ennemy_number: int

# Duplicate in ShipController
var selected_ennemy_array: Array[Node3D]

@export var enemies_data: Array[EnemiesData]

signal ennemy_selected(selected_enemy: Node3D)

# Called when the node enters the scene tree for the first time.
func _ready():
	ennemy_number = 0
	label.text = "Ennemy: " + str(ennemy_number)
	ennemy_array = []
	
	# Load all enemies from enemies_data array
	load_enemies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("spawn"):
		ennemy_number+=1
		label.text = "Ennemy: " + str(ennemy_number)
		spawn_ennemy()

func spawn_ennemy():
	var gltf_scene: PackedScene = load(little_ennemy_path)
	if gltf_scene:
		# Instance the scene
		var enemy: Node3D = gltf_scene.instantiate()
		enemy.get_child(0).rotation.y = PI
		
		var enemy_script: Script = load("res://Scripts/Ennemy/Ennemy.gd")
		if enemy_script:
			# Add the script to the enemy instance
			enemy.get_child(0).set_script(enemy_script)
			
		# Set ennemy moving zone
		enemy.get_child(0).width = 50
		enemy.get_child(0).height = 50
		
		# Connect the signal from the enemy instance to the manager
		enemy.get_child(0).set_enemy_selected.connect(_on_enemy_selected)
		
		ennemy_array.append(enemy)

		# Add the instance to the current scene
		add_child(enemy)

		# Optionally, set the position, rotation, or scale of the instantiated object
		enemy.position = Vector3(randi()%50-25, 7, randi()%50-25)
	else:
		print("Failed to load the GLTF file")

func load_enemies():
	for i in range(0, enemies_data.size()):
		var gltf_scene: PackedScene = load(enemies_data[i].enemy_path)
		if gltf_scene:
			for e in range(0, enemies_data[i].enemy_number):
				var enemy: Node3D = gltf_scene.instantiate()
				enemy.get_child(0).rotation.y = PI
				#var enemy_script: Script = load("res://Scripts/Ennemy/Ennemy.gd")
				#if enemy_script:
					# Add the script to the enemy instance
					#enemy.get_child(0).set_script(enemy_script)
					
				# Set ennemy moving zone
				var width = enemies_data[i].enemy_spawn_zone_width
				var height = enemies_data[i].enemy_spawn_zone_height
				enemy.get_child(0).width = width
				enemy.get_child(0).height = height
				
				# Connect the signal from the enemy instance to the manager
				enemy.get_child(0).set_enemy_selected.connect(_on_enemy_selected)
				enemy.get_child(0).set_enemy_dead.connect(_on_enemy_dead)
				
				ennemy_array.append(enemy)

				# Add the instance to the current scene
				add_child(enemy)

				# Optionally, set the position, rotation, or scale of the instantiated object
				enemy.position = enemies_data[i].enemy_spawn_zone_position
				enemy.get_child(0).spawn_position = enemies_data[i].enemy_spawn_zone_position
				enemy.get_child(0).target = enemies_data[i].enemy_spawn_zone_position
		else:
			print("Failed to load the GLTF file")

func _on_enemy_selected(selected_enemy: Node3D):
	# Emit signal to not move character
	ennemy_selected.emit(selected_enemy)
	
	if selected_enemy.get_child(0).is_outline:
		# Handle the enemy selection logic
		if selected_ennemy_array.has(selected_enemy):
			# Deselect the previously selected enemy (optional)
			selected_ennemy_array.remove_at(selected_ennemy_array.find(selected_enemy))
	else:
		# Select the new enemy
		selected_ennemy_array.append(selected_enemy)
	
	if selected_enemy.get_child(0).has_method("toggle_outline"):
		selected_enemy.get_child(0).call("toggle_outline")

func _on_enemy_dead(enemy: Node3D):
	ennemy_selected.emit(enemy)
	if selected_ennemy_array.find(enemy) != -1:
		remove_child(enemy)
		selected_ennemy_array.remove_at(selected_ennemy_array.find(enemy))
		ennemy_array[ennemy_array.find(enemy)].visible = false
