extends Node3D


func _enter_tree():
	#Sets the person in control of this player to it's id/the id of the person controlling
	set_multiplayer_authority(name.to_int())
