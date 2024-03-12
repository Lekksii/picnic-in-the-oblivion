#@tool
extends EditorPlugin

const editorPlugin = preload("res://engine_objects/pito_editor_plugin.tscn")
var dockedScene

func _enter_tree():
	dockedScene = editorPlugin.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR,dockedScene)
	
func _exit_tree():
	remove_control_from_docks(dockedScene)
	dockedScene.free()
