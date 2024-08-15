extends Node2D

@export var player : PackedScene
var manager_name := "Node"

# Called when the node enters the scene tree for the first time.
func _ready():
	var s = player.instantiate()
	add_child(s)
	s.get_node(manager_name).setup_audio(multiplayer.get_unique_id())
	


