@icon("res://addons/OvaniAmbiencePlugin/AmbienceAreaIcon.png")
@tool
extends Area3D
class_name AmbienceArea3D

## This node controls where a certain "Snapshot"
## of the existing audio busses is used.
## Use CollisionShape3D nodes to define its shape,
## and create more sub-areas by parenting more AmbienceArea3D
## nodes under this one.

static var _currentTween : Tween

@export
var _setupChildrenTrigger : bool
@export 
var _affectedZones : bool
@export
var _saveSnapshot : bool

## These "Snapshots" of the audio busses are transitioned towards when the 
## zone is entered.
@export
var Snapshots : Array[BusSnapshot] = []

## This is how long it'll take for the 
## Audio Busses to transition to this zone's Snapshot.
@export_range(0, 10)
var TransitionTime : float = .5

## In case Parent-Child Structuring is problematic, you can Indirectly connect
## Child zones with this Array.
@export
var IndirectChildAmbiences : Array[AmbienceArea3D] = []

## Validates Indirect Children or Parents, to avoid any recursion issues.
func VerifyIndirectAreas():
	var invalids : Array[AmbienceArea3D] = []
	if (IndirectParentAmbience != null):
		if (get_parent() is AmbienceArea3D):
			IndirectParentAmbience.IndirectChildAmbiences.erase(self)
			IndirectParentAmbience = null
		elif !IndirectParentAmbience.IndirectChildAmbiences.has(self):
			IndirectParentAmbience = null
	for extChil in IndirectChildAmbiences:
		if (extChil == null):
			continue;
		if (extChil == self):
			invalids.push_back(self)
			continue;
		if (extChil.get_parent() is AmbienceArea3D):
			invalids.push_back(extChil)
			continue;
		if (extChil.GetChildrenAreas().has(self)):
			invalids.push_back(extChil)
			continue;
		if (get_children().has(extChil)):
			invalids.push_back(extChil)
			continue;
		if (extChil.IndirectParentAmbience != self):
			if extChil.IndirectParentAmbience != null:
				extChil.IndirectParentAmbience.IndirectChildAmbiences.erase(extChil)
			extChil.IndirectParentAmbience = self
	for invalid in invalids:
		IndirectChildAmbiences.erase(invalid)
		invalid.IndirectParentAmbience = null


## If this zone is Indirectly a child via another Zone's IndirectChildAmbiences,
## This var will refer to it.
var IndirectParentAmbience : AmbienceArea3D

## Whether or not this is the current Ambience Zone the player is in.
var ActiveAmbience : bool = false

## Returns all Areas connected to this one through the tree.
## Gets children and parent's children.
func GetAssociatedAreas() -> Array[AmbienceArea3D]:
	var o : Array[AmbienceArea3D] = GetParentAreas()
	if (len(o) == 0):
		o.push_back(self)
	o = [o[0]]
	for chil in o[0].GetChildrenAreas():
		o.push_back(chil)
	return o

## Returns all the connected Areas Bus names.
func GetAssociatedBuses() -> Array[StringName]:
	var o : Array[StringName] = []
	for a in GetAssociatedAreas():
		o.push_back(a.name)
	return o

## Gets this AmbienceArea3Ds children AmbienceArea3Ds
func GetChildrenAreas() -> Array[AmbienceArea3D]:
	var o : Array[AmbienceArea3D] = []
	_getChildAreas(self, o)
	return o
## Gets this AmbienceArea3Ds children AmbienceArea3Ds Busses
func GetChildrenBuses() -> Array[StringName]:
	var o : Array[StringName] = []
	for c in GetChildrenAreas():
		o.push_back(c.name)
	return o

func _getChildAreas(source : AmbienceArea3D, childs : Array[AmbienceArea3D]):
	var newChilds : Array[Node] = source.get_children().duplicate()
	newChilds.append_array(source.IndirectChildAmbiences)
	for child in newChilds:
		if (child is AmbienceArea3D and not childs.has(child)):
			childs.push_back(child)
			
			_getChildAreas(child, childs)

func GetParentArea():
	if (IndirectParentAmbience != null):
		return IndirectParentAmbience
	else:
		return get_parent()

## Gets this AmbienceArea3Ds Parent AmbienceArea3Ds
func GetParentAreas() -> Array[AmbienceArea3D]: 
	var curParent : Node = GetParentArea()
	var founds : Array[AmbienceArea3D] = []
	while(true):
		if (curParent is AmbienceArea3D):
			founds.push_back(curParent)
			
			if !(curParent.get_parent() is AmbienceArea3D):
				if !(founds.has(curParent.IndirectParentAmbience)):
					curParent = curParent.IndirectParentAmbience
					continue;
			curParent = curParent.get_parent()
			continue
		founds.reverse()
		return founds
	return []

func _enter_tree():
	if Engine.is_editor_hint():	
		return
	ActiveAmbience = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	area_shape_entered.connect(_on_area_entered)
	area_shape_exited.connect(_on_area_exited)
	
	# Make sure the bus exists asap, so saved audio listeners find it.
	_ensureBus()
	_ensureBus()
	_ensureBus()


func _process(_delta):
	_ensureBus()
	_lastBusCount = AudioServer.bus_count
	
	_c = _c + 1
	if (_c > 50):
		_c = 0
		VerifyIndirectAreas()
var _c : int = 0



var _lastName : StringName = "pre init!!! 5rt4ey"
## The remembered index of this AmbienceArea3D's bus.
var busIndex : int = -1
var _lastBusCount : int = -1
func _ensureBus():
	print(name + "   " + str(busIndex) + " tot: " + str(AudioServer.bus_count))
	if (_lastBusCount == -1):
		_lastBusCount = AudioServer.bus_count
	if (busIndex >= AudioServer.bus_count):
		for i in AudioServer.bus_count:
			if (name == AudioServer.get_bus_name(i)):
				busIndex = i
				return
		_lastName = "pre init!!! 5rt4ey"
	if (_lastName == "pre init!!! 5rt4ey"):
		_lastName = name
		AudioServer.add_bus()
		busIndex = AudioServer.bus_count - 1
		AudioServer.set_bus_name(busIndex, name)
	
	if (busIndex == -1 || busIndex >= AudioServer.bus_count || AudioServer.get_bus_name(busIndex) != name):
		for i in AudioServer.bus_count:
			if (name == AudioServer.get_bus_name(i)):
				busIndex = i
				return
				
		if (_lastName == AudioServer.get_bus_name(busIndex) and _lastName != name):
			# Node Name changed!
			AudioServer.set_bus_name(busIndex, name)
			for ambArea in GetAssociatedAreas():
				for snap in ambArea.Snapshots:
					snap.Name == _lastName
					snap.Name = name
			_lastName = name
			return
		elif (_lastBusCount == AudioServer.bus_count):
			# Bus Name Change!
			name = AudioServer.get_bus_name(busIndex)
			for ambArea in GetAssociatedAreas():
				for snap in ambArea.Snapshots:
					snap.Name == _lastName
					snap.Name = name
			_lastName = name
			return
		else:
			# bus count changed, assume ours was unjustly deleted.
			# make a new bus.
			_lastName = "pre init!!! 5rt4ey"


func _exit_tree():
	for i in AudioServer.bus_count:
		if (name == AudioServer.get_bus_name(i)):
			AudioServer.remove_bus(i)
			return

var _childAmbiences : Array[StringName]
func _on_area_entered(area_rid:RID, area:Area3D, area_shape_index:int, local_shape_index:int):
	if (area.get_parent() is MovingAudioSource):
		if (area.get_parent().get_parent() is AudioStreamPlayer3D):
			var player : AudioStreamPlayer3D = area.get_parent().get_parent()
			if player.bus not in GetChildrenBuses():
				player.bus = name
func _on_area_exited(area_rid:RID, area:Area3D, area_shape_index:int, local_shape_index:int):
	if (area.get_parent() is MovingAudioSource):
		if (area.get_parent().get_parent() is AudioStreamPlayer3D):
			if (get_parent() is AmbienceArea3D):
				area.get_parent().get_parent().bus = get_parent().name
			else:
				area.get_parent().get_parent().bus = "Master"

func _fadeInto():
	if (_currentTween != null):
		_currentTween.kill()
		_currentTween = null
	_currentTween = self.create_tween()
	
	
	for snap in Snapshots:
		# figure bus
		var busIdx : int
		for i in AudioServer.bus_count:
			if (AudioServer.get_bus_name(i) == snap.Name):
				busIdx = i
		# todo fade bus volume AudioServer.set_bus_volume_db(busIdx, snap.Volume)
		var curVol : float = AudioServer.get_bus_volume_db(busIdx)
		var callback : Callable = func(vol): AudioServer.set_bus_volume_db(busIdx, vol)
		_currentTween.tween_method(callback, curVol, snap.Volume, TransitionTime)
		# if the bus doesn't match in effects, we can't fade.
		# replace all with ours.
		if AudioServer.get_bus_effect_count(busIdx) != len(snap.Effects):
			for i in AudioServer.get_bus_effect_count(busIdx):
				AudioServer.remove_bus_effect(busIdx, 0)
			for effect in snap.Effects:
				AudioServer.add_bus_effect(busIdx, effect.duplicate())
			var i : int = 0
			for state in snap.States:
				AudioServer.set_bus_effect_enabled(busIdx, i, state)
				i = i + 1
			continue;
		else:
			var i : int = 0
			for state in snap.States:
				AudioServer.set_bus_effect_enabled(busIdx, i, state)
				i = i + 1
			for j in AudioServer.get_bus_effect_count(busIdx):
				var effect : AudioEffect = AudioServer.get_bus_effect(busIdx, j)
				for prop in effect.get_property_list():
					if prop.type in [TYPE_FLOAT, TYPE_INT, TYPE_BOOL]:
						_currentTween.tween_property(effect, prop.name, snap.Effects[j][prop.name], TransitionTime)
	
	if (len(Snapshots) != 0):
		_currentTween.play()


func _on_body_entered(body : Node3D):
	for child in body.get_children():
		if (child is AmbienceListener):
			ActiveAmbience = true
			_fadeInto()
func _on_body_exited(body : Node3D):
	for child in body.get_children():
		if (child is AmbienceListener):
			ActiveAmbience = false
	if GetParentArea() is AmbienceArea3D:
		var par : AmbienceArea3D = GetParentArea()
		if par.overlaps_body(body):
			par._on_body_entered(body)
