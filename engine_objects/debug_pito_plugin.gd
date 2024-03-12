#@tool
extends Control
@export var enabled : bool = true

var eds
var selected_node

func _enter_tree():
	#if enabled:
	#eds = EditorPlugin.new().get_editor_interface().get_selection()
	
	eds.connect("selection_changed",_on_selection_changed,0)
	$VBoxContainer/copy_position.pressed.connect(_on_copy_position_pressed)
	$VBoxContainer/copy_rotation.pressed.connect(_on_copy_rotation_pressed)

func _on_selection_changed():
	var selected = eds.get_selected_nodes() 
	if not selected.is_empty():
		selected_node = selected[0]

func _on_copy_position_pressed():
	#print(selected_node)
	if selected_node != null:
		#print("[TOOL] PITO Editor: %s was selected!" % selected_node.name)
		var obj_position = "%.2f, %.2f, %.2f" % [selected_node.position.x,selected_node.position.y,selected_node.position.z]
		DisplayServer.clipboard_set(obj_position)
		#print("[TOOL] PITO Editor: position was copied to clipboard!")

func _on_copy_rotation_pressed():
	if selected_node != null:
		#print("[TOOL] PITO Editor: %s was selected!" % selected_node.name)
		var obj_rotation = "%.2f, %.2f, %.2f" % [selected_node.rotation.x,selected_node.rotation.y,selected_node.rotation.z]
		DisplayServer.clipboard_set(obj_rotation)
		#print("[TOOL] PITO Editor: rotation was copied to clipboard!")
