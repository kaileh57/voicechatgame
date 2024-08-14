extends EditorInspectorPlugin



func _can_handle(object):
	return object is AmbienceArea3D or object is AudioStreamPlayer3D


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if (object != null and object is AmbienceArea3D):
		curArea = object
		var dissallowed = [
			"audio_bus_override", 
			"audio_bus_name",
			"reverb_bus_enabled",
			"reverb_bus_name",
			"reverb_bus_amount",
			"reverb_bus_uniformity"]
		if name in dissallowed:
			return true
		if name == "_setupChildrenTrigger" and type == TYPE_BOOL:
			var button : Button = Button.new()
			button.text = "Auto Configure Contained SFX"
			button.pressed.connect(_SetupChildrenPressed)
			add_property_editor("", button)
			
			return true
		if name == "_affectedZones" and type == TYPE_BOOL:
			var label : Label = Label.new()
			var o : String = "Associated Buses: "
			for b in curArea.GetAssociatedBuses():
				o += b + ", "
			o = o.substr(0, o.length() - 2)
			label.text = o
			add_property_editor("", label)
			return true
		if name == "_saveSnapshot" and type == TYPE_BOOL:
			var lay : HBoxContainer = HBoxContainer.new()
			lay.alignment = BoxContainer.ALIGNMENT_CENTER
			var button : Button = Button.new()
			button.text = "Save Bus Snapshot"
			button.pressed.connect(_SaveSnapshot)
			lay.add_child(button)
			button = Button.new()
			button.text = "Load Bus Snapshot"
			button.pressed.connect(_LoadSnapshot)
			lay.add_child(button)
			add_property_editor("", lay)
			
			return true
		return false
	else:
		if name == "bus":
			var plr : AudioStreamPlayer3D = object
			for chil in plr.get_children():
				if (chil is MovingAudioSource):
					var lab : Label = Label.new()
					lab.text = "Audio Bus already handled by MovingAudioSource."
					add_property_editor("", lab)
					return true
			
			return false 

var curArea : AmbienceArea3D

func _SaveSnapshot():
	var targets : Array[AmbienceArea3D] = curArea.GetAssociatedAreas()
	curArea.Snapshots = []
	for targ in targets:
		var newSnap : BusSnapshot = BusSnapshot.new()
		newSnap.Name = AudioServer.get_bus_name(targ.busIndex)
		newSnap.Volume = AudioServer.get_bus_volume_db(targ.busIndex)
		for i in AudioServer.get_bus_effect_count(targ.busIndex):
			newSnap.Effects.push_back(AudioServer.get_bus_effect(targ.busIndex, i).duplicate())
			newSnap.States.push_back(AudioServer.is_bus_effect_enabled(targ.busIndex, i))
		curArea.Snapshots.push_back(newSnap)
	curArea.notify_property_list_changed()
func _LoadSnapshot():
	for snap in curArea.Snapshots:
		var busIdx : int
		for i in AudioServer.bus_count:
			if (AudioServer.get_bus_name(i) == snap.Name):
				busIdx = i
		AudioServer.set_bus_volume_db(busIdx, snap.Volume)
		for i in AudioServer.get_bus_effect_count(busIdx):
			AudioServer.remove_bus_effect(busIdx, 0)
		for effect in snap.Effects:
			AudioServer.add_bus_effect(busIdx, effect.duplicate())
		var i : int = 0
		for state in snap.States:
			AudioServer.set_bus_effect_enabled(busIdx, i, state)
			i = i + 1
	# force visual refresh
	AudioServer.add_bus(0)
	AudioServer.remove_bus(1)
# Auto Config SFX stuff below
var allRIDS

func _SetupChildrenPressed():
	var sources : Array[AudioStreamPlayer3D] = []
	var scene_root : Node = AmbiencePlugin.get_edited_scene_root()
	GetAllAudioChildren(scene_root, sources)
	
	allRIDS = [curArea.get_rid()]
	allRIDS.clear()
	var allZones : Array[Area3D]
	GetAllZoneChildren(scene_root, allZones)
	for zone in allZones:
		allRIDS.push_back(zone.get_rid())
	
	SetupZone(curArea, sources)

func GetAllAudioChildren(node : Node, childs : Array[AudioStreamPlayer3D]):
	for child in node.get_children():
		if (child is AudioStreamPlayer3D):
			childs.push_back(child)
		GetAllAudioChildren(child, childs)

func GetAllZoneChildren(node : Node, childs : Array[Area3D]):
	for child in node.get_children():
		if (child is AmbienceArea3D):
			childs.push_back(child)
		GetAllZoneChildren(child, childs)

func SetupZone(zone : AmbienceArea3D, audio_sources : Array[AudioStreamPlayer3D]):
	var parentRIDs = allRIDS.duplicate(false)
	parentRIDs.erase(zone.get_rid())
	
	for source in audio_sources:
		if PointInArea(zone, source.global_position, parentRIDs):
			source.bus = zone.name
	for child in zone.get_children():
		if child is AmbienceArea3D:
			SetupZone(child, audio_sources)

func PointInArea(area : Area3D, point : Vector3, exclusions : Array) -> bool:
	var space = area.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(point + Vector3(0, 9999, 0), point)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.hit_from_inside = true
	query.hit_back_faces = true
	query.exclude = exclusions
	var result : Dictionary = space.intersect_ray(query)
	
	return "collider" in result and result["collider"] == area
