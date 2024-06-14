extends Control

var game_tab_scene: PackedScene
var dashboard_scene: PackedScene
var game_instance: Node
var dashboard_instance: Node

func _ready():
	game_tab_scene = preload("res://Scenes/game.tscn")
	dashboard_scene = preload("res://Scenes/Menu/Dashboard.tscn")

	# Load tab scenes but keep them hidden initially
	load_tab_content($TabContainer/Base, dashboard_scene)
	
	# Connect the TabContainer's signals to handle tab changes
	$TabContainer.tab_changed.connect(_on_tab_changed)
	
	# Initialize the visibility
	_on_tab_changed($TabContainer.current_tab)

func load_tab_content(tab_node: Control, scene: PackedScene):
	var instance = scene.instantiate()
	var viewport_container = tab_node.get_node("SubViewportContainer/SubViewport")
	viewport_container.add_child(instance)
	
	# Store the instance for visibility management
	if tab_node.name == "Base":
		dashboard_instance = instance
	elif tab_node.name == "Game":
		game_instance = instance

func _on_tab_changed(tab_index):
	if tab_index == 1:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if !game_instance:
			load_tab_content($TabContainer/Game, game_tab_scene)
		game_instance.visible = true
		dashboard_instance.visible = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if game_instance:
			game_instance.visible = false
		dashboard_instance.visible = true

func _on_gui_input(event):
	# Block input from going to other tabs
	event.consume()

func _input(event):
	if Input.is_action_just_pressed("show_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
