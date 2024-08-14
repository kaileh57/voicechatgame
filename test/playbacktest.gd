extends Node

@onready var input = $Input
var index : int
var effect :AudioEffectCapture
var playback: AudioStreamGenerator

@export var output_path : NodePath

var input_thresh = 0.005

# Called when the node enters the scene tree for the first time.
func _ready():
	setupAudio(1)

func setupAudio(id):
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
		
	playback = get_node(output_path).get_stream_playback()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_multiplayer_authority():
		process_mic()

func process_mic():
	var stereo_data : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if stereo_data.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereo_data.size())
		var max_amplitude : float = 0.0
		
		for i in range(stereo_data.size()):
			var val = (stereo_data[1].x + stereo_data[i].y)/2
			max_amplitude = max(val, max_amplitude)
			data[i] = val
		if max_amplitude < input_thresh:
			return
		
		print(data)
