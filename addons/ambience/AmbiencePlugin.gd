@tool
extends EditorPlugin
class_name AmbiencePlugin


static func get_edited_scene_root():
	return Instance.get_editor_interface().get_edited_scene_root()
static var Instance : EditorPlugin

func _enter_tree():
	Instance = self
	add_inspector_plugin(preload("res://addons/OvaniAmbiencePlugin/AmbienceInspectorPlugin.gd").new())

func _exit_tree():
	pass
