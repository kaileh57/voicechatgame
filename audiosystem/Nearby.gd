extends Node3D


var choked := false
var drowning := false
var echo := 0.0
var reverb := 0.0

@export var reverb_check: Area3D
@export var echo_check: Area3D
@export var echoext_check: Area3D
@export var echo_cancel_check: Area3D


#Checks for stuff like echo and reverb
func check():
	var bodies = reverb_check.get_overlapping_areas()
	for i in bodies:
		if i.has_method("cause_reverb"):
			reverb += 0.5
	if bodies != null:
		bodies = echo_cancel_check.get_overlapping_areas()
		echo = -1
	bodies = echo_check.get_overlapping_areas()
	if echo != -1:
		for i in bodies:
			if i.has_method("cause_echo"):
				echo += 0.1
	bodies = echoext_check.get_overlapping_areas()
	if echo != -1:
		for i in bodies:
			if i.has_method("cause_echo"):
				echo += 0.05
	if echo == -1: echo = 0

func _physics_process(_delta):
	check()

#Applies audio effects before sending out the audio
func process_audio_effects():
	pass



