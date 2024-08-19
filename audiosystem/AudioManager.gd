extends Node3D

@export var input : AudioStreamPlayer
var index: int
var effect: AudioEffectCapture
var playback : AudioStreamGeneratorPlayback

var input_threshold = 0.05

func _ready():
	setup_audio(1)

func setup_audio(id):
	input = $Input
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
	
	playback = $OutputPath.get_stream_playback()

func _process(_delta):
	if is_multiplayer_authority():
		process_mic()

func process_mic():
	var stereo_data: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if stereo_data.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereo_data.size())
		var max_amplitude := 0.0
		for i in range(stereo_data.size()):
			var value = (stereo_data[i].x + stereo_data[i].y)/2
			max_amplitude = max(value, max_amplitude)
			data[i] = value
		if max_amplitude < input_threshold:
			return
		print(data)
