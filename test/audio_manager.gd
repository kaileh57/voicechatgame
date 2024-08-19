extends Node

@onready var input : AudioStreamPlayer 
var index : int
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
@export var outputPath : NodePath
var inputThreshold = 0.02
var receiveBuffer := PackedFloat32Array()

var fade := 0
# Called when the node enters the scene tree for the first time.
func _ready():
	#setupAudio(1)
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
	#if is_multiplayer_authority():
	#	processMic()
	#processVoice()
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
