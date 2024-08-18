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
	bodies = echo_cancel_check.get_overlapping_areas()
	if bodies != null: echo = -1
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

func _physics_process(delta):
	check()

#Applies audio effects before sending out the audio
func process_audio_effects():
	pass





@onready var input : AudioStreamPlayer 
var index : int
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
@export var outputPath : NodePath
var inputThreshold = 0.02
var receiveBuffer := PackedFloat32Array()

var fade := 0
# Called when the node enters the scene tree for the first time.
func ready():
	setupAudio(1)
	pass # Replace with function body.

func setupAudio(id):
	input = $Input
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)

	playback = get_node(outputPath).get_stream_playback()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_multiplayer_authority():
		processMic()
	processVoice()
	pass

func processMic():
	var sterioData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if sterioData.size() > 0:
		
		var data = PackedFloat32Array()
		data.resize(sterioData.size())
		var maxAmplitude := 0.0
		
		for i in range(sterioData.size()):
			var value = (sterioData[i].x + sterioData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
		
		if maxAmplitude < inputThreshold:
			fade -= 1
		else:
			fade = 40
		if fade <= 0:
			return
		
		sendData.rpc(data)
		#sendData(data)
		

func processVoice():
	if receiveBuffer.size() <= 0:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)

@rpc("any_peer", "call_remote", "unreliable")
func sendData(data : PackedFloat32Array):
	receiveBuffer.append_array(data)



var peer = ENetMultiplayerPeer.new()
@export var playerScene : PackedScene
var clientConnected : bool
@export var gameSpawnLocation : NodePath
# Called when the node enters the scene tree for the first time.
func __ready():
	multiplayer.peer_connected.connect(peerConnected)
	multiplayer.peer_disconnected.connect(peerDisconnected)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta):
	if clientConnected:
		peer.poll()
	pass

func peerConnected(id):
	print("peer connected! " + str(id))
	var p = playerScene.instantiate()
	get_node(gameSpawnLocation).add_child(p)
	p.name = str(id)
	p.get_node("AudioManager").setupAudio(id)

func peerDisconnected(id):
	print("peer disconnected! " + str(id))

func _on_connect_to_server_button_down():
	peer.create_client("localhost", 8910)
	
	multiplayer.multiplayer_peer = peer
	
	var p = playerScene.instantiate()
	get_node(gameSpawnLocation).add_child(p)
	p.name = str(multiplayer.get_unique_id())
	p.get_node("AudioManager").setupAudio(multiplayer.get_unique_id())
	clientConnected = true
	#AudioServer.set_bus_mute(AudioServer.get_bus_index("Record"), true)
	pass # Replace with function body.
