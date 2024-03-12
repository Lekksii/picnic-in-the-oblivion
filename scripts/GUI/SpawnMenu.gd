extends ColorRect

@onready var GM : GameManager = GameManager
@onready var player : Player = GameManager.player
@onready var gui : GUI = GameManager.Gui

@onready var items_list : ItemList = $TabContainer/Items/ItemList
@onready var levels_list : ItemList = $TabContainer/Levels/LevelList

func _on_add_item_btn_pressed():
	if items_list.get_selected_items().size() > 0:
		gui.InventoryWindow.AddItem(items_list.get_item_text(items_list.get_selected_items()[0]))

func _on_load_lvl_btn_pressed():
	if levels_list.get_selected_items().size() > 0:
		GM.change_level(levels_list.get_item_text(levels_list.get_selected_items()[0]))
		self.hide()

func Open():
	show()
	
	if items_list.item_count > 0:
		items_list.clear()
		
	if levels_list.item_count > 0:
		levels_list.clear()
	
	if GM.items_json:
		for item_id in GM.items_json:
			items_list.add_item(item_id,Utility.load_external_texture(GM.items_json[item_id]["icon"]))
	
	for lvl_id in DirAccess.get_directories_at(GM.app_dir+"assets/levels/"):
		levels_list.add_item(lvl_id)


func _on_visibility_changed():
	if visible:
		GM.pause = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		GM.pause = false
		if not GameManager.Gui.IntroWindow.visible and not GameManager.Gui.death_screen.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#return
