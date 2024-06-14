extends Node3D

@export var ship: PackedScene

func _ready():
	add_child(ship.instantiate())
