extends Control
class_name LootWindow
@onready var loot_list_node : Object = $ItemsScroll/items_list
@onready var loot_list_player_node = $ItemsScrollPlayer/items_list_player
@onready var loot_sel_name : Label = $selectedItemTitle
@onready var loot_sel_desc : Label = $DescriptionScroll/selectedItemDescr
@onready var loot_sel_icon : TextureRect = $SelectedIcon
@onready var take_all_btn : Button = $TakeAll
@onready var weight_title : Label = $weight_item_title
@onready var price_title : Label = $weight_item_price
@onready var descr_scroll : ScrollContainer = $DescriptionScroll
@onready var money : Label = $money
@onready var weight : Label = $weight
@onready var take_item_btn : Button = $TakeItem

@onready var items_scroll : ScrollContainer = $ItemsScroll
@onready var items_scroll_player : ScrollContainer = $ItemsScrollPlayer

@onready var items_signal_loot_l : TextureRect = $items_loot_signal_l
@onready var items_signal_loot_r : TextureRect = $items_loot_signal_r
@onready var items_signal_player_l : TextureRect = $items_player_signal_l
@onready var items_signal_player_r : TextureRect = $items_player_signal_r

var can_be_looted : bool = true
var inventory : Inventory = null

signal on_item_took
signal on_item_delete

var _loot_id = ""
var loot_list = []
var items_node_list = []
var _scroll_timer = 0.0
var scroll_delay = 0.6

func _ready():
	weight_title.text = Lang.translate("ui.statistic.weight")
	price_title.text = Lang.translate("inv.itm.stat.price")
	_scroll_timer = scroll_delay

func _CheckItemsPositionForLightElements():
	
	# if loot items in list
	if loot_list_node.get_child_count() > 0:
		var last_child = loot_list_node.get_child(loot_list_node.get_child_count()-1)
		#print("last child [%s] -> %.2f\nitems_scroll size [%s] -> %.2f" % [last_child.name, last_child.position.x, items_scroll.name, items_scroll.size.x])
		
		if last_child.position.x > items_scroll.size.x-16:
			items_signal_loot_r.show()
		
		var current_scroll = (items_scroll.scroll_horizontal + items_scroll.size.x - last_child.size.x)
		
		if current_scroll >= last_child.position.x-32:
			
			items_signal_loot_r.hide()
			
		if loot_list_node.get_child(0).position.x < items_scroll.scroll_horizontal:
			items_signal_loot_l.show()
		else:
			items_signal_loot_l.hide()
	# if player items in list
	if loot_list_player_node.get_child_count() > 0:
		var last_child = loot_list_player_node.get_child(loot_list_player_node.get_child_count()-1)
		if last_child.position.x + 32 > items_scroll_player.size.x:
			items_signal_player_r.show()

		var current_scroll = (items_scroll_player.scroll_horizontal + items_scroll_player.size.x - last_child.size.x)
		if current_scroll >= last_child.position.x-32:
			items_signal_player_r.hide()
			
		if loot_list_player_node.get_child(0).position.x < items_scroll_player.scroll_horizontal-32:
			items_signal_player_l.show()
		else:
			items_signal_player_l.hide()

func UpdateLoot():
	
	if inventory == null:
		inventory = GameManager.Gui.InventoryWindow as Inventory
	
	for children in loot_list_node.get_children():
		children.queue_free()
		
	for p_itm in loot_list_player_node.get_children():
		p_itm.queue_free()
	
	await get_tree().process_frame
	
	can_be_looted = true
	
	for loot in loot_list:
		_add_item_to_loot(loot)
		
	for inv_itm in GameManager.Gui.InventoryWindow.items_list:
		_add_item_to_player(inv_itm)
	
	await get_tree().process_frame
	
	_CheckItemsPositionForLightElements()
	
func AddItemToLoot(id):
	loot_list.append(id)
	UpdateLoot()

func TakeItemFromLoot(id):
	loot_list.erase(id)
	print("erase %s" % id)
	if OS.has_feature("mobile"):
		GameManager.Gui.InventoryWindow.AddItem(id)
		_clear_selection_texts()
		emit_signal("on_item_took",id)
		on_item_took_callback(id)
		GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
	UpdateLoot()
	print("update loot")
	#can_be_looted = true

func LoadLoot(loot_id):
	if inventory == null:
		inventory = GameManager.Gui.InventoryWindow as Inventory
	
	if loot_list.size() == 0:
	
		take_all_btn.position = take_item_btn.position
		take_all_btn.size = take_item_btn.size
	
		# clear old
		loot_list.clear()
		
		for children in loot_list_node.get_children():
			children.queue_free()
			
		for p_itm in loot_list_player_node.get_children():
			p_itm.queue_free()
		
		#await get_tree().process_frame
		
		# add items to loot list (ITS JUST ID's)
		if loot_id in GameManager.loot_json:
			for loot_item in GameManager.loot_json[loot_id]["items"] if !GameManager.casual_gameplay or GameManager.casual_gameplay and "items_casual" not in GameManager.loot_json[loot_id] else GameManager.loot_json[loot_id]["items_casual"]:
				loot_list.append(loot_item)
		
		# if id list not empty - add items to slots	
		if len(loot_list) > 0:
			for loot in loot_list:
				_add_item_to_loot(loot)
		
		for inv_itm in GameManager.Gui.InventoryWindow.items_list:
			#print("add %s" % inv_itm)
			_add_item_to_player(inv_itm)
			
	else:
		UpdateLoot()
		
	_update_weight()
	items_scroll.scroll_horizontal = 0
	items_scroll_player.scroll_horizontal = 0
	await get_tree().process_frame
	_CheckItemsPositionForLightElements()

func _update_weight():
	$weight_player.text = "%.2f / %.0f KG" % [inventory.weight, inventory.weight_max]

func on_item_took_callback(item_id):
	_update_weight()
	#print("%s was taken from lootbox" % item_id)

func on_item_send_callback(item_id):
	_update_weight()

func on_item_del_callback():
	pass
	#print("Loot count: %s" %str(loot_list_node.get_child_count()))

func _add_item_to_loot(id):
	if id in GameManager.items_json:
		var item = preload("res://engine_objects/item.tscn").instantiate()
		item.ID = id
		item.keys = GameManager.items_json[id]
		item.name = id+"_"+str(item.get_instance_id())
		item.weight = snappedf(item.keys["weight"],0.01)
		item.OWNER = self
		loot_list_node.add_child(item)
		items_node_list.append(item)
		
func _add_item_to_player(itm):
	var item = preload("res://engine_objects/item.tscn").instantiate()
	item.ID = itm.ID
	item.keys = itm.keys
	item.name = itm.ID+"_"+str(item.get_instance_id())
	item.weight = snappedf(item.keys["weight"],0.01)
	item.OWNER = self
	item.equipped = itm.equipped
	item.instance_id = itm.instance_id
	loot_list_player_node.add_child(item)

func Open():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_loot_open"])
	if loot_list.size() > 0:
		take_all_btn.show()
	else:
		take_all_btn.hide()
	self.show()
	#_CheckItemsPositionForLightElements()
	
func Close():
	_clear_selection_texts()
	self.hide()
	if not GameManager.Gui.death_screen.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#Clear()
	if GameManager.level_is_safe:
		GameManager.SaveGame()
	

func IsOpened():
	if self.visible:
		return true
	else:
		return false

func Clear():
	if len(loot_list) > 0:		
		loot_list.clear()
		
		for node_itm in items_node_list:
			if is_instance_valid(node_itm):
				node_itm.queue_free()
				
		await get_tree().process_frame
		# destroy loot object in world
		_loot_id= ""
		Close()

func TakeAll():
	if not IsOpened(): return
	
	var total_weight = inventory.CheckTotalWeight(loot_list)
	if total_weight >= inventory.weight_max:
		GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
		# stop function, so items won't be given to player
		return
	
	if len(loot_list) > 0:
		for itm in loot_list:
			inventory.AddItem(itm)
			emit_signal("on_item_took",itm)
		
		loot_list.clear()
		
		for node_itm in items_node_list:
			if is_instance_valid(node_itm):
				node_itm.queue_free()
				
		await get_tree().process_frame
		# destroy loot object in world
		if GameManager.player.raycast.get_collider():
			if GameManager.player.raycast.get_collider().get_parent().keys["loot_id"] == _loot_id:
				GameManager.player.raycast.get_collider().get_parent().queue_free()
		_loot_id= ""
		Close()

func _process(_delta):
	if loot_sel_desc.text != "":
		_scroll_timer -= _delta
		if _scroll_timer <= 0:
			descr_scroll.scroll_vertical += 8
			_scroll_timer = scroll_delay
	
	if IsOpened() and len(loot_list_node.get_children()) == 0:
		if OS.has_feature("windows"):
			set_process(false)
			GameManager.player.can_look = false
			await get_tree().create_timer(0.2).timeout
			if GameManager.obj_player_looked != null:
				if GameManager.obj_player_looked.keys["loot_id"] == _loot_id:
					GameManager.obj_player_looked.queue_free()
			_loot_id= ""
			GameManager.player.can_look = true
			set_process(true)
			
		if OS.has_feature("mobile"):
			GameManager.player.can_look = false
			if GameManager.obj_player_looked != null:
				if GameManager.obj_player_looked.keys["loot_id"] == _loot_id:
					GameManager.obj_player_looked.queue_free()
			_loot_id= ""
			GameManager.player.can_look = true
		Close()
		
	
	if GameManager._key_pressed("take_all"):
		TakeAll()
	
	if IsOpened() and Input.is_action_just_released("pause"):
		#TakeAll()
		Close()

func _clear_selection_texts():
	loot_sel_name.text = ""
	loot_sel_desc.text = ""
	loot_sel_icon.texture = null
	money.text = "0$"
	weight.text = "0 kg"
					
func _on_take_all_pressed():
	TakeAll()


func _on_items_scroll_scroll_started():
	_CheckItemsPositionForLightElements()


func _on_items_scroll_player_scroll_started():
	_CheckItemsPositionForLightElements()


func _on_items_scroll_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			items_scroll.emit_signal("scroll_started")
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			items_scroll.emit_signal("scroll_started")


func _on_items_scroll_player_gui_input(event):
	_on_items_scroll_gui_input(event)


func _on_take_item_pressed():
	for loot in loot_list_node.get_children():
		if loot.selected and not loot.equipped:
			var _weight_calculator = GameManager.Gui.InventoryWindow.weight + loot.weight
								
			if _weight_calculator < GameManager.Gui.InventoryWindow.weight_max:
				print("take loot mobile")
				TakeItemFromLoot(loot.ID)
			else:
				loot._select_item(false)
				GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
			break
			
	for p_itm in loot_list_player_node.get_children():
		if p_itm.selected and not p_itm.equipped:
			GameManager.Gui.InventoryWindow.DeleteItem(p_itm.instance_id)
			AddItemToLoot(p_itm.ID)
			on_item_send_callback(p_itm.ID)
			GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
			break
