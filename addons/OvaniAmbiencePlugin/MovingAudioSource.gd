@icon("res://addons/OvaniAmbiencePlugin/MovingAudioSourceIcon.png")
@tool
extends Node3D
class_name MovingAudioSource

## This Node Should be placed under an AudioStreamPlayer3D.
## It will track what AmbienceArea3D it's in, and adjust the
## AudioStreamPlayer3Ds Target Bus accordingly.

func _ready():
	_add_col()

func _add_col():
	var ar = Area3D.new()
	add_child(ar, false, Node.INTERNAL_MODE_FRONT)
	ar.name = get_parent().name
	var col = CollisionShape3D.new()
	ar.add_child(col, false, Node.INTERNAL_MODE_FRONT)
	var col_col : SphereShape3D = SphereShape3D.new()
	col.shape = col_col
	col_col.radius = .01
