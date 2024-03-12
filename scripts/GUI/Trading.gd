extends Control
class_name TradingSystem 
@export var trader_items_list : Control
@export var player_items_list : Control

@export var parameter_list : Control
@export var loot_sel_name : Label
@export var loot_sel_desc : Label
@export var loot_sel_icon : TextureRect
@export var trader_descr_scroll : ScrollContainer
@export var trader_scroll : ScrollContainer
@export var player_scroll : ScrollContainer

@export var item_weight : Label
@export var item_money : Label
@export var item_selected_weight : Label
@export var item_selected_money : Label

@onready var items_signal_loot_l : TextureRect = $items_loot_signal_l
@onready var items_signal_loot_r : TextureRect = $items_loot_signal_r
@onready var items_signal_player_l : TextureRect = $items_player_signal_l
@onready var items_signal_player_r : TextureRect = $items_player_signal_r

var traders
var _scroll_timer = 0.0
var scroll_delay = 0.6

func _load_trader(trader_id : String):
	traders = GameManager.traders_json[trader_id]

# Set autoscroll speed of trader window item description
func set_autoscroll_delay(delay : float):
	scroll_delay = delay
	_scroll_timer = scroll_delay
	trader_descr_scroll.scroll_vertical = 0	

func clear_all_selections():
	#for param in parameter_list.get_children():
	#	param.queue_free()
	for trader_item in trader_items_list.get_children():
		trader_item._select_item(false)
	for player_item in player_items_list.get_children():
		player_item._select_item(false)
	loot_sel_name.text = ""
	loot_sel_desc.text = ""
	#item_weight.text = "0 kg"
	#item_money.text = "0$"
	item_selected_weight.text = "0 kg"
	item_selected_money.text = "0$"
	loot_sel_icon.texture = null

func _clear():
	for param in parameter_list.get_children():
		param.queue_free()
	for trader_item in trader_items_list.get_children():
		trader_item.queue_free()
	for player_item in player_items_list.get_children():
		player_item.queue_free()
	loot_sel_name.text = ""
	loot_sel_desc.text = ""
	item_weight.text = "0 kg"
	item_money.text = "0$"
	item_selected_weight.text = "0 kg"
	item_selected_money.text = "0$"
	loot_sel_icon.texture = null
	#print("+ [TRADER]: Очищено!")
	
func set_preview_icon_type(type : String):
	match type:
		"basic":
			loot_sel_icon.pivot_offset = Vector2(122,42)
			loot_sel_icon.set_size(Vector2(245,85))
			loot_sel_icon.rotation_degrees = 0
			loot_sel_icon.set_position(Vector2(1130,455))
		"outfit":
			loot_sel_icon.set_position(Vector2(1208,532))
			loot_sel_icon.set_size(Vector2(85,245))
			loot_sel_icon.rotation_degrees = 90
	
func _update_bags():
	_clear()
	#await get_tree().create_timer(0.1).timeout
	#print("+ [ITEMS LIST]: " + str(GameManager.Gui.InventoryWindow.items_list))
	for player_item in GameManager.Gui.InventoryWindow.items_list:
		_add_items_player(player_item)
	
	for trader_item in traders["items"]:
		_add_items_trader(trader_item)
	
	item_selected_money.add_theme_color_override("font_color",Color("a9a5a2"))
	_update_money()
	GameManager.weapon_system.UpdateAmmo()
	set_preview_icon_type("basic")
	await get_tree().process_frame
	_CheckItemsPositionForLightElements()
	#print("+ [TRADER]: Предметы обновлены!")

func _update_money():
	item_money.text = "%s$" % GameManager.player.money
	item_weight.text = "%.2f / %.0f %s" % [GameManager.Gui.InventoryWindow.weight,GameManager.Gui.InventoryWindow.weight_max,Lang.translate("kg")]
	
func _add_items_player(itm : item):
	
	var _item = preload("res://engine_objects/item.tscn").instantiate()
	_item.ID = itm.ID
	_item.keys = itm.keys
	_item.instance_id = itm.instance_id
	_item.OWNER = self
	_item.SetStack(itm.stack)
	player_items_list.add_child(_item)
	_item.name = itm.ID+"_"+str(itm.instance_id)

func _add_items_trader(id):
	var item = preload("res://engine_objects/item.tscn").instantiate()
	item.ID = id
	item.keys = GameManager.items_json[id]
	item.name = id+"_"+str(item.get_instance_id())
	item.OWNER = self
	trader_items_list.add_child(item)
		
func Open(trader_id : String):
	_load_trader(trader_id)
	_update_bags()
	self.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return
	
# Close inventory func
func Close():
	await get_tree().process_frame
	if not GameManager.Gui.death_screen.visible and IsOpened():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager.level_is_safe:
		GameManager.SaveGame()
	self.hide()
	return
	

# Check if inventory is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false
		
func _process(_delta):
	if loot_sel_desc.text != "":
		_scroll_timer -= _delta
		if _scroll_timer <= 0:
			trader_descr_scroll.scroll_vertical += 8
			_scroll_timer = scroll_delay
			
	if IsOpened() and Input.is_action_just_pressed("pause") and not GameManager.Gui.TradingMessage.visible:
		Close()
		if GameManager.Gui.PauseWindow.visible:
			GameManager.Gui.PauseWindow.Close()
		

func _CheckItemsPositionForLightElements():
	
	# if loot items in list
	if trader_items_list.get_child_count() > 0:
		var last_child = trader_items_list.get_child(trader_items_list.get_child_count()-1)
		#print("last child [%s] -> %.2f\nitems_scroll size [%s] -> %.2f" % [last_child.name, last_child.position.x, items_scroll.name, items_scroll.size.x])
		
		if last_child.position.x > trader_scroll.size.x-16:
			items_signal_loot_r.show()
		
		var current_scroll = (trader_scroll.scroll_horizontal + trader_scroll.size.x - last_child.size.x)
		
		if current_scroll >= last_child.position.x-32:
			
			items_signal_loot_r.hide()
			
		if trader_items_list.get_child(0).position.x < trader_scroll.scroll_horizontal:
			items_signal_loot_l.show()
		else:
			items_signal_loot_l.hide()
	# if player items in list
	if player_items_list.get_child_count() > 0:
		var last_child = player_items_list.get_child(player_items_list.get_child_count()-1)
		if last_child.position.x + 32 > player_scroll.size.x:
			items_signal_player_r.show()

		var current_scroll = (player_scroll.scroll_horizontal + player_scroll.size.x - last_child.size.x)
		if current_scroll >= last_child.position.x-32:
			items_signal_player_r.hide()
			
		if player_items_list.get_child(0).position.x < player_scroll.scroll_horizontal-32:
			items_signal_player_l.show()
		else:
			items_signal_player_l.hide()

func _on_items_scroll_trader_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			trader_scroll.emit_signal("scroll_started")
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			trader_scroll.emit_signal("scroll_started")


func _on_items_scroll_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			player_scroll.emit_signal("scroll_started")
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player_scroll.emit_signal("scroll_started")


func _on_items_scroll_trader_scroll_started():
	_CheckItemsPositionForLightElements()


func _on_items_scroll_scroll_started():
	_CheckItemsPositionForLightElements()
