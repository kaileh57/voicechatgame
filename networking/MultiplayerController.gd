extends Node

func _ready():
	#If we are in control of this player, we'll use this camera
	pass


@export var player : CharacterBody3D
@onready var cam = player.CAMERA
@export var root: Node3D

func _enter_tree():
	#Sets the person in control of this player to it's id/the id of the person controlling

	set_multiplayer_authority(root.name.to_int())

	cam = player.CAMERA
	cam.current = true
	
	player.set_multiplayer_authority(root.name.to_int())

@rpc("authority", "call_remote", "unreliable")
func update_pos(pos: Vector3):
	player.position = pos

func _physics_process(delta):
	if is_multiplayer_authority():
		update_pos.rpc(player.position)
