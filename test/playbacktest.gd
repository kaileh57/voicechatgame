extends Node
class_name playbackT

@onready var input = $Input
var index : int
var effect :AudioEffectCapture
var playback: AudioStreamGenerator

@export var output_path : NodePath

var input_thresh = 0.005

var inc_buffer := PackedFloat32Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass#setup_audio(1)

func setup_audio(id):
	input = $Input
	set_multiplayer_authority(id)
	#if is_multiplayer_authority():
	input.stream = AudioStreamMicrophone.new()
	input.play()
	index = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(index, 0)
	playback = get_node(output_path).get_stream_playback()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_multiplayer_authority():
		process_mic()
		#process_voice()

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
		
		#send_data.rpc(data)
		send_data(data)

func process_voice():
	if inc_buffer.size() <= 0:
		return
	for i in range(min(playback.get_frames_available(), inc_buffer.size())):
		playback.push_frame(Vector2(inc_buffer[0], inc_buffer[0]))
		inc_buffer.remove_at(0)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_data(data: PackedFloat32Array):
	inc_buffer.append_array(data)
