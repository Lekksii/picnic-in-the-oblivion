extends Panel
class_name Inventory

@onready var item_list_node = $ItemsScroll/items_list
@onready var items_scroll : ScrollContainer = $ItemsScroll
@onready var descr_scroll : ScrollContainer = $DescriptionScroll
@onready var loot_sel_name : Label = $selectedItemTitle
@onready var loot_sel_desc : Label = $DescriptionScroll/VBoxContainer/selectedItemDescr
@onready var loot_sel_icon : TextureRect = $SelectedIcon

@onready var slot_pistol_icon : slot = $PistolSlotIcon
@onready var slot_rifle_icon : slot = $RifleSlotIcon
@onready var slot_outfit_icon : slot = $OutfitSlotIcon

@onready var slot_belt0_icon : slot = $Belt0SlotIcon
@onready var slot_belt1_icon : slot = $Belt1SlotIcon
@onready var slot_belt2_icon : slot = $Belt2SlotIcon
@onready var slot_belt3_icon : slot = $Belt3SlotIcon

@onready var parameter_list = $DescriptionScroll/VBoxContainer/SelectedParameters
@onready var weight_text : Label = $weight

@onready var r_light_panel : TextureRect = $items_signal_r
@onready var l_light_panel : TextureRect = $items_signal_l
@onready var selected_item_weight : Label = $item_veight

var is_open_from_pause : bool = false

var pistol_slot : item
var rifle_slot : item
var outfit_slot : item
var belt : Array

var _autoscroll_delay = 0.5
var _autoscroll_timer = 1.0
var weight : float = 0.0
var weight_max : float = 10.0

var items_list = []

func _ready():
	InventoryInit()
	belt = [slot_belt0_icon, slot_belt1_icon, slot_belt2_icon, slot_belt3_icon]
	
# Find item in inventory
func Find(id):
	for i in items_list:
		if i.ID == id:
			return i	
	
func GetAllItemsIDs():
	var _list = []
	for i in items_list:
		_list.append(i.ID)
	return _list
	
func GetAllEquippedItemsIDs():
	var _list = []
	for i in items_list:
		if i.equipped:
			_list.append(i.ID)
	return _list
	
func ResetInventorySystem():
	# firstly unequip all equipped items in slots
	for i in items_list:
		if i.equipped:
			print(i.ID + " was equipped, unload it!")
			i._is_wipe = true
			i.UseItem()
			i._clear_selection_texts()
	
	for i_node in item_list_node.get_children():
		i_node.SelfDestroy()
	
	r_light_panel.hide()
	l_light_panel.hide()
	
# Using for items init at game start
func _game_ready_inventory():
	GameManager.Gui.weapon_icon.texture = null
	#AddItem("w_pistol").UseItem()
	#AddItem("w_lr").UseItem()

func _GetItemInSlot(slot):
	if slot == "pistol":
		return slot_pistol_icon.equipped_item
	if slot == "rifle":
		return slot_rifle_icon.equipped_item
	if slot == "outfit":
		return slot_outfit_icon.equipped_item
	if slot == "belt1":
		return slot_belt0_icon.equipped_item
	if slot == "belt2":
		return slot_belt1_icon.equipped_item
	if slot == "belt3":
		return slot_belt2_icon.equipped_item
	if slot == "belt4":
		return slot_belt3_icon.equipped_item

func InventoryInit():
	slot_pistol_icon.texture = null
	slot_rifle_icon.texture = null
	slot_outfit_icon.texture = null
	slot_belt0_icon.texture = null
	slot_belt1_icon.texture = null
	slot_belt2_icon.texture = null
	slot_belt3_icon.texture = null

func DeleteItem(instance_id):
	for itm in item_list_node.get_children():
		if itm.name == itm.ID+"_"+instance_id:
			items_list.erase(itm)
			weight -= snappedf(itm.weight,0.01)
			itm.queue_free()

func CheckTotalWeight(list_items_ids : Array):
	var _full_weight : float = 0.0
	var _player_current_weight : float = snappedf(GameManager.Gui.InventoryWindow.weight, 0.01)
	for itm in list_items_ids:
		_full_weight += snappedf(GameManager.items_json[itm]["weight"],0.01)
	var _check_weight : float = _player_current_weight + _full_weight
	#print(_check_weight)
	return _check_weight
	
func FindItem(instance_id):
	for itm in item_list_node.get_children():
		if itm.name == itm.ID+"_"+instance_id:
			return itm

func CheckItemsPositionForLightElements():
	if item_list_node.get_child_count() > 0:
		var last_child = item_list_node.get_child(item_list_node.get_child_count()-1)
		#print("Currnet Scroll: %.2f \nSize inv: %d\nPos Item Last: %.2f\nPos Item First: %.2f" % [items_scroll.scroll_horizontal,items_scroll.size.x,item_list_node.get_child(item_list_node.get_child_count()-1).position.x,item_list_node.get_child(0).position.x])
		if item_list_node.get_child(item_list_node.get_child_count()-1).position.x > items_scroll.size.x:
			r_light_panel.show()

		var current_scroll = (items_scroll.scroll_horizontal + items_scroll.size.x - last_child.size.x)
		if current_scroll >= last_child.position.x:
			r_light_panel.hide()
			
		if item_list_node.get_child(0).position.x < items_scroll.scroll_horizontal:
			l_light_panel.show()
		else:
			l_light_panel.hide()

func GetItemsTypeAmount(id:String):
	var amount = 0
	#print("Get %s amount" % id)
	for itm in item_list_node.get_children():
		#print(itm.ID)
		if id == itm.ID:
			#print("Found item! Add stack!")
			amount += itm.stack
			continue
	return amount

# Add item by id form items.json file
func AddItem(id):
	if id in GameManager.items_json:
		# We check if future weight will be enough to take it
		var _weight_calculator = weight + snappedf(GameManager.items_json[id].weight, 0.01)
		
		if _weight_calculator < weight_max:
			var item = preload("res://engine_objects/item.tscn").instantiate()
			
			var del_after_stack = false
			item.ID = id
			item.keys = GameManager.items_json[id]
			item.weight = snappedf(item.keys.weight, 0.01)
			item.name = id+"_"+str(item.get_instance_id())
			item.OWNER = self
			#item.custom_minimum_size = item.icon.size
			#item.update_minimum_size()
			item.instance_id = str(item.get_instance_id())
			weight += snappedf(item.weight,0.01)
			for itm in items_list:
				if itm.ID == item.ID and item.keys["type"] == "usable":
					#print("+ Знайшов дублікат предмету %s!\n+ Прибавляю +1 до стеку" % itm.ID)
					if itm.stack < itm.max_stack:
						itm.AddStack(1)
						#print("+ Стек доданий!")
						del_after_stack = true
						#item.SelfDestroy()
						#item = null
						#print("+ Оригінальний предмет, який був створений, але не доданий в інвентар - знищено!\n\n")
					else:
						#print("+ Не можу знайти дублікат предмета, щоб додати стек, тому пошукаю ще...\n\n")
						continue
			if del_after_stack:
				item.SelfDestroy()
				return
				
			item_list_node.add_child(item)
			items_list.append(item)
			GameManager.weapon_system.UpdateAmmo()
			GameManager.Gui.UpdateHUDAmounts()
			UpdateWeight()
			if item.ID == "medkit" or item.ID == "medkit_army":
				if GameManager.DontHasEventKey("has.medkit"):
					GameManager.AddEventKey("has.medkit")
			return item
		else:
			GameManager.Gui.ShowMessage(Lang.translate("message.no.weight"))

func Open():
	if not GameManager.weapon_system.is_reloading:
		UpdateWeight()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		self.show()
		await get_tree().process_frame
		if items_scroll.scroll_horizontal != 0:
			items_scroll.scroll_horizontal = 0
		CheckItemsPositionForLightElements()
# Close inventory func
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
	if GameManager.level_is_safe:
		GameManager.SaveGame()
	ClearAllSelections()
	
func ClearAllSelections():
	# check if we have some selected item before we close and deselect them
	for itm in item_list_node.get_children():
		if is_instance_valid(itm):
			if itm.selected:
				itm._select_item(false)

# Check if inventory is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false
		
func UpdateWeight():
	weight_text.text = "%.2f / %.0f %s" % [weight,weight_max,Lang.translate("kg")]
		
func _process(_delta):
	if loot_sel_desc.text != "":
		_autoscroll_timer -= _delta * 1
	else:
		_autoscroll_timer = _autoscroll_delay
	
	if _autoscroll_timer <= 0:
		#var a = descr_scroll.scroll_vertical + descr_scroll.size.y - parameter_list.get_child(parameter_list.get_child_count()-1).size.y if parameter_list.get_child_count() > 0 else 0
		#var b = descr_scroll.scroll_vertical + descr_scroll.size.y - loot_sel_desc.size.y
		descr_scroll.scroll_vertical += 8
		#print((descr_scroll.scroll_vertical - descr_scroll.get_child(0).size.y + descr_scroll.size.y) + descr_scroll.scroll_vertical)
		#print("scroll: %d" % descr_scroll.scroll_vertical)
		
		#print("scroll: %s" % str(descr_scroll.scroll_vertical))
		#print("a: %s" % str(a))
		#print("b: %s" % str(b))
		#print("a+b: %s" % str(a+b))
		##if parameter_list.get_child_count() > 0:
		#	if descr_scroll.scroll_vertical >= a:
		#		descr_scroll.scroll_vertical = 0
		#		_autoscroll_timer = _autoscroll_delay
				
		#else:
		#	if descr_scroll.scroll_vertical >= a+b:
		#		descr_scroll.scroll_vertical = 0
		#		_autoscroll_timer = _autoscroll_delay
				
		_autoscroll_timer = _autoscroll_delay
		if descr_scroll.scroll_vertical == ((descr_scroll.scroll_vertical - descr_scroll.get_child(0).size.y + descr_scroll.size.y) + descr_scroll.scroll_vertical):
			set_process(false)
			await get_tree().create_timer(1).timeout
			descr_scroll.scroll_vertical = 0
			set_process(true)


func _on_items_scroll_scroll_started():
	CheckItemsPositionForLightElements()


func _on_items_scroll_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			items_scroll.emit_signal("scroll_started")
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			items_scroll.emit_signal("scroll_started")
