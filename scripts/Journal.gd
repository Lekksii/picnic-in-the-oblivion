class_name Journal extends ColorRect

@export var list_nodes_quests : Control
var quest_text = preload("res://engine_objects/quest_text.tscn")
var is_open_from_pause : bool = false

func AddQuest(id : String, title : String):
	if list_nodes_quests.get_child_count() < 8:
		var new_q : Label = quest_text.instantiate()
		new_q.name = id
		new_q.text = title
		list_nodes_quests.add_child(new_q)

func Open():
	if not GameManager.weapon_system.is_reloading:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if list_nodes_quests.get_child_count() > 0:
			for children in list_nodes_quests.get_children():
				children.queue_free()
		
		for q in GameManager.quests:
			AddQuest(q,GameManager.quests[q]["title"])
		self.show()
	
# Close func
func Close():
	if not is_open_from_pause:
		hide()
		if not GameManager.Gui.death_screen.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.pause = false
	else:
		hide()
		GameManager.Gui.PauseWindow.show()
		is_open_from_pause = false

# Check if inventory is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false
			
