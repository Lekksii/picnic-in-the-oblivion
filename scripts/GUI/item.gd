extends Control
class_name item 
var ID : String
var keys : Dictionary
var OWNER
var instance_id = ""

var equipped : bool = false
var selected : bool = false
var _is_wipe = false

@export var equipped_text : Label 
@export var stack_text : Label
@export var icon : TextureRect

var stack : int = 1
var max_stack : int = 1
var weight : float = 0.0

func AddStack(value):
	stack += value
	if stack > 1:
		stack_text.show()
		#stack_text.set_size(Vector2(40,32))
	stack_text.text = "x%s" % stack
	GameManager.Gui.UpdateHUDAmounts()
	
func SetStack(value):
	stack = value
	if stack > 1:
		stack_text.show()
		#stack_text.set_size(Vector2(40,32))
	stack_text.text = "x%s" % stack
	
func MinusStack(value):
	stack -= value
	if stack == 1:
		stack_text.hide()
		#stack_text.set_size(Vector2(40,32))
	stack_text.text = "x%s" % stack
	GameManager.Gui.UpdateHUDAmounts()

func DeleteItem():
	if stack > 1:
		MinusStack(1)
	else:
		SelfDestroy()

func _ready():
	icon.texture = Utility.load_external_texture(keys["icon"])
	if "slot" in keys and keys["slot"] == "outfit":
		var icon_rotated : Image = icon.texture.get_image() as Image
		icon_rotated.rotate_90(CLOCKWISE)
		icon.texture = ImageTexture.create_from_image(icon_rotated)
	
	self.weight = keys["weight"]
	if stack > 1:
		stack_text.show()
	
	# connect callback to function in p_game.gd
	#GameManager.on_item_used.connect(GameManager.GameProcess.on_item_used)

func _select_item(b: bool):
	var color_selected_normal = "ee9d31" #ee9d31 orange
	var color_selected_equipped = "17FFF1"
	var color_selected_disabled = "e80000"
	var style_selector : StyleBoxFlat =  StyleBoxFlat.new()
	style_selector.draw_center = false
	style_selector.border_width_bottom = 4
	style_selector.border_width_left = 4
	style_selector.border_width_right = 4
	style_selector.border_width_top = 4
	
	selected = b
	$selector.set_size(Vector2(self.size.x,self.size.y))
	if selected:
		if OS.has_feature("mobile"):
			if OWNER is LootWindow:
				OWNER.take_all_btn.position = Vector2(895,760)
				OWNER.take_all_btn.size = Vector2(465,70)
				OWNER.take_item_btn.show()
				
		_update_selection_texts()
		# IF ITEM SELECTED
		# IF ITEM EQUIPPED
		if equipped:
			style_selector.border_color = Color(color_selected_equipped)
			$selector.add_theme_stylebox_override("panel",style_selector)
			if OWNER is Inventory:
				var inv = OWNER as Inventory
				for s in inv.get_children():
					if s is slot:
						if s.equipped_item and s.equipped_item.ID == ID:
							s.get_node("selector").show()
							s.get_node("selector").add_theme_stylebox_override("panel",style_selector)
							break
			if OWNER is LootWindow:
				if get_parent().name == "items_list_player":
					style_selector.border_color = Color(color_selected_disabled)
					$selector.add_theme_stylebox_override("panel",style_selector)
					
		# IF ITEM NOT EQUIPPED
		else:
			style_selector.border_color = Color(color_selected_normal)
			$selector.add_theme_stylebox_override("panel",style_selector)
			
			if "slot" in keys and keys["slot"] == "belt":
				for belt in range(1,4):
					if GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%belt) != null and GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%belt).equipped:
						if not equipped and GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%belt).ID == ID:
							style_selector.border_color = Color(color_selected_disabled)
							$selector.add_theme_stylebox_override("panel",style_selector)
							break
			
		$selector.visible = true
		if OWNER is TradingSystem:
			if get_parent().name == "trader_items_list":
				if GameManager.player.money < keys["price"]:
					style_selector.border_color = Color(color_selected_disabled)
					$selector.add_theme_stylebox_override("panel",style_selector)
					OWNER.item_selected_money.add_theme_color_override("font_color",color_selected_disabled)
				else:
					OWNER.item_selected_money.add_theme_color_override("font_color",color_selected_normal)
			if get_parent().name == "player_items_list":
				if OWNER.traders["dont_want_to_buy"].has(ID) or GameManager.Gui.InventoryWindow.FindItem(instance_id).equipped:
					style_selector.border_color = Color(color_selected_disabled)
					$selector.add_theme_stylebox_override("panel",style_selector)
					OWNER.item_selected_money.add_theme_color_override("font_color",color_selected_disabled)
	else:
		if OS.has_feature("mobile"):
			if OWNER is LootWindow:
				OWNER.take_item_btn.hide()
				OWNER.take_all_btn.position = OWNER.take_item_btn.position
				OWNER.take_all_btn.size = OWNER.take_item_btn.size
				
		if OWNER is Inventory:
			var inv = OWNER as Inventory
			for s in inv.get_children():
				if s is slot:
					if s.has_node("selector"):
						s.get_node("selector").hide()
		_clear_selection_texts()
		$selector.visible = false

func SelfDestroy():
	if OWNER is Inventory:
		OWNER.weight -= snapped(weight,0.01)
		OWNER.UpdateWeight()
		OWNER.items_list.erase(self)
	self.queue_free()

func _add_parameter_bar(ParameterWindow, param, weapon_id=""):
	var new_parameter_bar : inv_parameter_bar = preload("res://engine_objects/parameter_bar.tscn").instantiate()
	ParameterWindow.parameter_list.add_child(new_parameter_bar)
	new_parameter_bar.name = "bar_param_"+param
	match param:
		"heal":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			new_parameter_bar.parameter_bar.max_value = GameManager.player.health_max
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.heal")
			new_parameter_bar.parameter_bar.value = keys["on_use"][param]
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_bar.show()
		
		"heal2":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			#new_parameter_bar.parameter_bar.max_value = GameManager.player.health_max
			new_parameter_bar.parameter_text2.text = "+ %d HP" % keys["on_use"]["heal"]
			#new_parameter_bar.parameter_bar.value = keys["on_use"][param]
			new_parameter_bar.parameter_text2.show()
			#new_parameter_bar.parameter_bar.show()
			
		"max_hp":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			#new_parameter_bar.parameter_bar.max_value = GameManager.player.health_max
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.max.hp")
			new_parameter_bar.parameter_bar.value = keys["on_use"][param]
			#new_parameter_bar.parameter_text2.text = "+ %d MAX HP" % keys["on_use"][param]
			new_parameter_bar.parameter_text.show()
			#new_parameter_bar.parameter_text2.show()
			new_parameter_bar.parameter_bar.show()
			
		"max_hp2":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			#new_parameter_bar.parameter_bar.max_value = GameManager.player.health_max
			#new_parameter_bar.parameter_text.text = "+ " + Lang.translate("inv.itm.stat.max.hp")
			#new_parameter_bar.parameter_bar.value = keys["on_use"][param]
			new_parameter_bar.parameter_text2.text = "+ %d MAX HP" % keys["on_use"]["max_hp"]
			#new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_text2.show()
			#new_parameter_bar.parameter_bar.show()
			
		"armor":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/armor_stat.png")
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.armor")
			new_parameter_bar.parameter_bar.value = keys["on_use"][param]
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_bar.show()
			
		"radiation":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.radiation")
			new_parameter_bar.parameter_bar.value = 100
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_bar.show()
			
		"radiation_timer":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.rad.timer")
			new_parameter_bar.parameter_text.show()
			
		"radiation_timer_trader":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.rad.timer")
			new_parameter_bar.parameter_text2.text = "30'"
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_text2.show()

		"flashlight":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.flashlight")
			new_parameter_bar.parameter_text.show()
		
		"separator":
			new_parameter_bar.parameter_text.text = " "
			new_parameter_bar.parameter_text.show()
		
		"price":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.price")
			new_parameter_bar.parameter_text2.text = "%s$" % keys["price"]
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_text2.show()
		
		"weight":
			new_parameter_bar.parameter_text.text = Lang.translate("ui.statistic.weight")
			new_parameter_bar.parameter_text2.text = "%.2f %s" % [weight,Lang.translate("kg")]
			#new_parameter_bar.parameter_text2.set_position(Vector2(new_parameter_bar.parameter_text.position.x + 32,new_parameter_bar.parameter_text.position.y))
			
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_text2.show()
		
		"stack":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.stack")
			new_parameter_bar.parameter_text2.text = "%d" % [stack]
			new_parameter_bar.parameter_text.show()
			new_parameter_bar.parameter_text2.show()
		
		"unequip":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.unequip")
			new_parameter_bar.parameter_text.show()

		"wpn_damage":
			if weapon_id != "":
				#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
				new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.damage")
				new_parameter_bar.parameter_bar.value = float(GameManager.weapons_json[weapon_id]["damage"]+(GameManager.weapons_json[weapon_id]["accuracy"]*100)+(GameManager.Gui.SkillWindow.accuracy*100)+GameManager.Gui.SkillWindow.strenght)
				new_parameter_bar.parameter_text.show()
				new_parameter_bar.parameter_bar.show()
		
		"no_sell":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.nosell")
			new_parameter_bar.parameter_text.show()
		
		"effects":
			new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.effects")
			new_parameter_bar.parameter_text.show()
		
		"speed":
			if weapon_id != "":
				new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.firerate")
				new_parameter_bar.parameter_bar.value = new_parameter_bar.parameter_bar.max_value - GameManager.weapons_json[weapon_id]["speed"] * 100
				new_parameter_bar.parameter_text.show()
				new_parameter_bar.parameter_bar.show()
		"wpn_accuracy":
			if weapon_id != "":
				#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
				new_parameter_bar.parameter_text.text = Lang.translate("inv.itm.stat.accuracy")
				new_parameter_bar.parameter_bar.value = ((GameManager.weapons_json[weapon_id]["accuracy"] * 100)+(GameManager.Gui.SkillWindow.accuracy*100))
				new_parameter_bar.parameter_text.show()
				new_parameter_bar.parameter_bar.show()
			
func _add_parameter(ParameterWindow,param,weapon_id="",type="standard"):
	var new_parameter : inv_parameter = null
	match type:
		"standard": new_parameter = preload("res://engine_objects/inv_parameter.tscn").instantiate()
		"green": new_parameter = preload("res://engine_objects/inv_parameter_green.tscn").instantiate()
		"red": new_parameter = preload("res://engine_objects/inv_parameter_red.tscn").instantiate()
	ParameterWindow.parameter_list.add_child(new_parameter)
	new_parameter.name = "param_"+param
	if type == "standard": new_parameter.separator.show()
	match param:
		"heal":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		"max_hp":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/hp_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		"armor":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/armor_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		
		"spacer":
			new_parameter.icon.texture = Utility.load_external_texture("assets/null.png")
			new_parameter.icon.set_size(Vector2(32,32))
			match type:
				"standard": new_parameter.parameter_text.text = ""
				"green": new_parameter.parameter_text_green.text = ""
				"red": new_parameter.parameter_text_green.text = ""
		
		"rad_resist":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		
		"accuracy":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		
		"strength":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/str_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		
		"anomaly_resist":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/anom_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("+%s" % keys["on_use"][param])+'%'
				"green": new_parameter.parameter_text_green.text = ("+%s" % keys["on_use"][param])+'%'
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
				
		"weight":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/weight_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = ("%s%s" % [keys["on_use"][param],Lang.translate("kg")])
				"green": new_parameter.parameter_text_green.text = ("%s%s" % [keys["on_use"][param],Lang.translate("kg")])
				"red": new_parameter.parameter_text_green.text = ("%s%s" % [keys["on_use"][param],Lang.translate("kg")])
				
		"radiation":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = "-100%"
				"green": new_parameter.parameter_text_green.text = "-100%"
				"red": new_parameter.parameter_text_green.text = ("%s" % keys["on_use"][param])+'%'
		"radiation_timer":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_stat.png")
			match type:
				"standard": new_parameter.parameter_text.text = "20 sec"
				"green": new_parameter.parameter_text_green.text = "20 sec"
			
		"flashlight":
			#new_parameter.icon.hide()
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/items/flashlight.png")
			new_parameter.parameter_text.text = Lang.translate("inv.itm.stat.flashlight")
			
		"unequip":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/lock.png")
			new_parameter.parameter_text.text = Lang.translate("inv.itm.stat.unequip")
			
		"story_item":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_icn.png")
			new_parameter.parameter_text.text = Lang.translate("inv.itm.stat.story")
			
		"price":
			#new_parameter.icon.texture = Utility.load_external_texture("assets/ui/rad_icn.png")
			new_parameter.parameter_text.text = "%s$" % keys["price"]
			
		"no_sell":
			new_parameter.icon.texture = Utility.load_external_texture("assets/ui/lock.png")
			new_parameter.parameter_text.text = Lang.translate("inv.itm.stat.nosell")
			
		"wpn_damage":
			if weapon_id != "":
				new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
				new_parameter.parameter_text.text = "DMG: %si" % str(GameManager.weapons_json[weapon_id]["damage"])
				
		"wpn_magazine":
			if weapon_id != "":
				#new_parameter.icon.hide()
				new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
				new_parameter.parameter_text.text = "MAG: %s" % GameManager.weapons_json[weapon_id]["clip_ammo_max"]
		
		"wpn_ammo":
			if weapon_id != "":
				#new_parameter.icon.hide()
				new_parameter.icon.texture = Utility.load_external_texture("assets/ui/dmg_stat.png")
				new_parameter.parameter_text.text = "AMMO TYPE: "
				new_parameter.AddIcon(GameManager.items_json[GameManager.weapons_json[weapon_id]["ammo_type"]]["icon"],3)
	
	new_parameter.icon.show()
	match type:
		"standard": new_parameter.parameter_text.show()
		"green": new_parameter.parameter_text_green.show()

func _update_selection_texts():
	if OWNER is LootWindow or OWNER is Inventory or OWNER is TradingSystem:
		OWNER.loot_sel_name.text = Lang.translate(keys["name"])
		OWNER.loot_sel_desc.text = Lang.translate(keys["caption"])
		OWNER.loot_sel_icon.texture = Utility.load_external_texture(keys["icon"])
		if OWNER is Inventory:
			OWNER.descr_scroll.scroll_vertical = 0
		if OWNER is LootWindow:
			OWNER.get_node("money").text = "%s$" % keys["price"]
			OWNER.get_node("weight").text = "%.2f %s" % [snappedf(weight,0.01),Lang.translate("kg")]
			
		if OWNER is TradingSystem:
			if "type" in keys:
				if keys["type"] == "weapon": OWNER.set_preview_icon_type("basic")
				if keys["type"] == "equipment" and "slot" in keys and keys["slot"] == "outfit": OWNER.set_preview_icon_type("outfit")
			else:
				OWNER.set_preview_icon_type("basic")
				
			OWNER.item_selected_weight.text = "%.2f %s" % [snappedf(keys["weight"],0.01),Lang.translate("kg")]
			
			if get_parent().name == "player_items_list" and ID not in OWNER.traders["dont_want_to_buy"]:
				OWNER.item_selected_money.text = "%d$" % int(int(keys["price"])/2) if not GameManager.casual_gameplay else "%d$" % int(keys["price"])
			else:
				#print("price")
				OWNER.item_selected_money.text = "%d$" % keys["price"]
		
		if OWNER is Inventory:
			OWNER.parameter_list.show()
			if "on_use" in keys and len(keys["on_use"]) > 0:
				if "action" not in keys["on_use"]:
					for param in keys["on_use"]:
						var type = "green"
						if typeof(keys["on_use"][param]) != TYPE_BOOL and keys["on_use"][param] > 0:
							type = "green"
						else:
							type = "red"
							
						if param == "radiation":
							type = "green"
							
						match param:
							"armor":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"armor","",type)
							"rad_resist":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"rad_resist","",type)
							"anomaly_resist":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"anomaly_resist","",type)
							"weight":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"weight","",type)
							"max_hp":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"max_hp","",type)
							"heal":
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
								_add_parameter(GameManager.Gui.InventoryWindow,"heal","",type)
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"stack")
							"radiation":
								_add_parameter(GameManager.Gui.InventoryWindow,"radiation","",type)
								#_add_parameter_bar(GameManager.Gui.InventoryWindow,"radiation_timer_trader")
								#_add_parameter(GameManager.Gui.InventoryWindow,"radiation_timer")
							"accuracy":
								_add_parameter(GameManager.Gui.InventoryWindow,"accuracy","",type)
							"strength":
								_add_parameter(GameManager.Gui.InventoryWindow,"strength","",type)
							#_:
								#_add_parameter(GameManager.Gui.InventoryWindow,param)
								
				else:
					if keys["on_use"]["action"] == "flashlight":
						OWNER.parameter_list.hide()
						#_add_parameter_bar(GameManager.Gui.InventoryWindow,"flashlight")
			
				#_add_parameter(GameManager.Gui.InventoryWindow,"spacer","","green")	
			if "type" in keys and keys["type"] == "weapon":
				if keys["slot"] == "pistol":
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"wpn_accuracy",keys["profile"])					
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"wpn_damage",keys["profile"])
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"speed",keys["profile"])
					#_add_parameter(GameManager.Gui.InventoryWindow,"unequip")
					#_add_parameter(GameManager.Gui.InventoryWindow,"story_item")
					
					#_add_parameter_bar(GameManager.Gui.InventoryWindow,"wpn_magazine",keys["profile"])
				if keys["slot"] == "rifle":
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"wpn_accuracy",keys["profile"])										
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"wpn_damage",keys["profile"])
					_add_parameter_bar(GameManager.Gui.InventoryWindow,"speed",keys["profile"])
					#_add_parameter(GameManager.Gui.InventoryWindow,"wpn_magazine",keys["profile"])
					#_add_parameter(GameManager.Gui.InventoryWindow,"wpn_ammo",keys["profile"])
			#_add_parameter_bar(GameManager.Gui.InventoryWindow,"weight")	
			OWNER.selected_item_weight.text = "%.2f %s" % [weight,Lang.translate("kg")]	
		if OWNER is TradingSystem:
			if "on_use" in keys and len(keys["on_use"]) > 0:
				for param in keys["on_use"]:
					if param == "action": continue
					var type = "green"
					if (typeof(keys["on_use"][param]) != TYPE_BOOL) and keys["on_use"][param] > 0:
						type = "green"
					else:
						type = "red"
					
					if param == "radiation":
						type = "green"
						
					match param:
						"armor":
							#_add_parameter_bar(GameManager.Gui.TradingWindow,"effects")
							_add_parameter(GameManager.Gui.TradingWindow,"armor","",type)
							#_add_parameter_bar(GameManager.Gui.TradingWindow,"separator")
						"rad_resist":
							#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
							_add_parameter(GameManager.Gui.TradingWindow,"rad_resist","",type)
						"anomaly_resist":
							#_add_parameter_bar(GameManager.Gui.InventoryWindow,"effects")
							_add_parameter(GameManager.Gui.TradingWindow,"anomaly_resist","",type)
						"max_hp":
							#_add_parameter_bar(GameManager.Gui.TradingWindow,"effects")
							_add_parameter(GameManager.Gui.TradingWindow,"max_hp","",type)
						"heal":
							#_add_parameter_bar(GameManager.Gui.TradingWindow,"effects")
							_add_parameter(GameManager.Gui.TradingWindow,"heal","",type)
						"radiation":
							_add_parameter(GameManager.Gui.TradingWindow,"radiation","",type)
						"weight":
							_add_parameter(GameManager.Gui.TradingWindow,"weight","",type)
						"accuracy":
							_add_parameter(GameManager.Gui.TradingWindow,"accuracy","",type)
						"strength":
							_add_parameter(GameManager.Gui.TradingWindow,"strength","",type)
							#_add_parameter(GameManager.Gui.TradingWindow,"radiation_timer")
						#_:
							#_add_parameter(GameManager.Gui.TradingWindow,param)
				#_add_parameter_bar(GameManager.Gui.TradingWindow,"separator")
				#_add_parameter_bar(GameManager.Gui.TradingWindow,"price")
					
			if "type" in keys and keys["type"] == "weapon":
				if keys["slot"] == "pistol":
					_add_parameter_bar(GameManager.Gui.TradingWindow,"wpn_accuracy",keys["profile"])										
					_add_parameter_bar(GameManager.Gui.TradingWindow,"wpn_damage",keys["profile"])
					_add_parameter_bar(GameManager.Gui.TradingWindow,"speed",keys["profile"])
					#_add_parameter_bar(GameManager.Gui.TradingWindow,"separator")
					#_add_parameter(GameManager.Gui.TradingWindow,"no_sell")
				if keys["slot"] == "rifle":
					_add_parameter_bar(GameManager.Gui.TradingWindow,"wpn_accuracy",keys["profile"])										
					_add_parameter_bar(GameManager.Gui.TradingWindow,"wpn_damage",keys["profile"])
					_add_parameter_bar(GameManager.Gui.TradingWindow,"speed",keys["profile"])
					#_add_parameter(GameManager.Gui.TradingWindow,"wpn_damage",keys["profile"])
					#_add_parameter(GameManager.Gui.TradingWindow,"wpn_magazine",keys["profile"])
					#_add_parameter(GameManager.Gui.TradingWindow,"wpn_ammo",keys["profile"])
					#_add_parameter_bar(GameManager.Gui.TradingWindow,"separator")
					#_add_parameter_bar(GameManager.Gui.TradingWindow,"price")
			#if keys["type"] == "item":
				#_add_parameter_bar(GameManager.Gui.TradingWindow,"price")
func _clear_selection_texts():
	if OWNER is LootWindow or OWNER is Inventory or OWNER is TradingSystem:
		OWNER.loot_sel_name.text = ""
		OWNER.loot_sel_desc.text = ""
		OWNER.loot_sel_icon.texture = null
		if OWNER is LootWindow:
			OWNER.get_node("money").text = "0$"
			OWNER.get_node("weight").text = "0 %s" % Lang.translate("kg")
			OWNER.descr_scroll.scroll_vertical = 0
			
		if OWNER is TradingSystem:
			OWNER.item_selected_weight.text = "--"
			OWNER.item_selected_money.text = "0$"
			OWNER.item_selected_money.add_theme_color_override("font_color",Color("a9a5a2"))
			OWNER.set_preview_icon_type("basic")
			OWNER.trader_descr_scroll.scroll_vertical = 0
			if GameManager.Gui.TradingWindow.parameter_list.get_child_count() > 0:
				for children in GameManager.Gui.TradingWindow.parameter_list.get_children():
					children.queue_free()
		
		if OWNER is Inventory:
			OWNER._autoscroll_timer = 1.0
			if GameManager.Gui.InventoryWindow.parameter_list.get_child_count() > 0:
				for children in GameManager.Gui.InventoryWindow.parameter_list.get_children():
					children.queue_free()
			OWNER.selected_item_weight.text = ""

func _equip_item(equipment_slot : slot):
	#stack_text.set_deferred("size",Vector2(32,32))
	#equipped_text.set_deferred("size",Vector2(32,32))
	if not equipped:
		if not equipment_slot.equipped_item:
			equipped_text.show()
			equipment_slot.equipped_item = self
			equipped = true
			equipment_slot.texture = icon.texture
		else:
			if keys["slot"] == "outfit" or keys["slot"] == "rifle":
				match keys["slot"]:
					"outfit":
						if "armor" in equipment_slot.equipped_item.keys["on_use"]:
							GameManager.Gui.SkillWindow.armor -= equipment_slot.equipped_item.keys["on_use"]["armor"]
						if "rad_resist" in equipment_slot.equipped_item.keys["on_use"]:
							GameManager.Gui.SkillWindow.radiation_resistance -= equipment_slot.equipped_item.keys["on_use"]["rad_resist"]
						if "anomaly_resist" in equipment_slot.equipped_item.keys["on_use"]:
							GameManager.Gui.SkillWindow.anomaly_resistance -= equipment_slot.equipped_item.keys["on_use"]["anomaly_resist"]
						if "weight" in equipment_slot.equipped_item.keys["on_use"]:
							GameManager.Gui.InventoryWindow.weight_max -= equipment_slot.equipped_item.keys["on_use"]["weight"]
							GameManager.Gui.InventoryWindow.UpdateWeight()
				equipment_slot.equipped_item.equipped = false
				equipment_slot.equipped_item.equipped_text.hide()
				equipped = true
				equipment_slot.equipped_item = self
				equipped_text.show()
				equipment_slot.texture = icon.texture
	#if keys["slot"] == "pistol" or keys["slot"] == "rifle":
	#	GameManager.Gui.weapon_icon.texture = self.texture
		
func UseItem():
	_clear_selection_texts()
	#var player : FreeLookCamera = GameManager.player as FreeLookCamera
	if keys["type"] == "usable":
		if "dialogue" in keys:
			if OWNER is Inventory:
				GameManager.player.can_use = false
				GameManager.player.can_look = false
				OWNER.Close()
				await get_tree().process_frame
				GameManager.Gui.PauseWindow.Close()
			
			GameManager.Gui.DialogueWindow.StartDialogue(keys["dialogue"]["id"],keys["dialogue"]["name"])
			await get_tree().create_timer(0.1).timeout
			GameManager.player.can_use = true
			GameManager.player.can_look = true
		
		if "on_use" in keys:
			if "heal" in keys["on_use"]:
				if GameManager.player.health < GameManager.player.health_max:
					# Create healing system based on percent from max HP
					# basic heal based on max hp without artefacts
					var percentage : float = (keys["on_use"]["heal"] * GameManager.player.health_max)/100.0
					var percentage_with_arts : float = 0.0
					var all_artefacts_max_hp : float = 0.0
					var final_result : float = 0.0
					# if item is inside inventory now
					if OWNER is Inventory:
						# loop through 4 slots
						for belt in range(1,4):
							# get item of every slot
							var belt_item = OWNER._GetItemInSlot("belt%d"%belt)
							# if slot has any item
							if belt_item != null:
								# check if item type is equipment and it has max hp effect
								if (belt_item.keys["type"] == "equipment" and 
								belt_item.keys["on_use"].keys().has("max_hp")):
									# add art effect of max health to var
									all_artefacts_max_hp += belt_item.keys["on_use"]["max_hp"]
									continue
					# if player has some artefacts affection on max hp
					# make some calculations
					if all_artefacts_max_hp > 0:
						# get medkit percentage from all artefacts effect sum
						percentage_with_arts = (keys["on_use"]["heal"] * all_artefacts_max_hp)/100.0
						# calculate final heal amount (max player hp % - max arts max hp %)
						final_result = snappedf((percentage - percentage_with_arts)+percentage,2)
						GameManager.player.Heal(final_result)
						#print("Player healed with med (player has arts): +%.2f (%.2f-%.2f)+%.2f | max hp: %.2f" % [final_result,percentage,percentage_with_arts,percentage,GameManager.player.health_max])
					else:
						GameManager.player.Heal(percentage)
						#print("Player healed with med (player has no arts): +%.2f" % percentage)
					
			if "radiation" in keys["on_use"] and keys["on_use"]["radiation"]:
				if not GameManager.player.antirad:
					GameManager.player.antirad = true
				else:
					GameManager.player.antirad_timer = 20.0
				
		if stack > 1:
			MinusStack(1)
		else:
			if ID == "medkit" or ID == "medkit_army":
				if GameManager.HasEventKey("has.medkit"):
					GameManager.DeleteEventKey("has.medkit")
			SelfDestroy()
		
	if keys["type"] == "weapon":
		if keys["slot"] == "rifle":
			if not equipped:
				#equipped_text.position.x = 86
				_equip_item(OWNER.slot_rifle_icon)
				_select_item(true)
			else:
				#last_magazine = GameManager.weapon_system.current_weapon.ammo_mag
				_select_item(false)
				equipped = false
				equipped_text.hide()
				OWNER.slot_rifle_icon.equipped_item = null
				OWNER.slot_rifle_icon.texture = null
				GameManager.weapon_system.DeleteWeapon("rifle",_is_wipe)
				_select_item(true)
			if not _is_wipe:
				GameManager.weapon_system.CheckWeaponsInInventorySlots()
				GameManager.weapon_system.DrawWeapon("rifle")
				
		if keys["slot"] == "pistol":
			if not equipped:
				equipped_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				equipped_text.position.x = 2
				#equipped_text.size.x = 32
				equipped_text.hide()
				equipped_text.add_theme_color_override("font_color",Color("e80000"))
				_equip_item(OWNER.slot_pistol_icon)
			else:
				if not _is_wipe:
					if keys["profile"] in GameManager.weapons_json:
						if "locked" not in GameManager.weapons_json[keys["profile"]] or "locked" in GameManager.weapons_json[keys["profile"]] and not GameManager.weapons_json[keys["profile"]]["locked"]:
							equipped = false
							equipped_text.hide()
							OWNER.slot_pistol_icon.equipped_item = null
							OWNER.slot_pistol_icon.texture = null
							GameManager.weapon_system.DeleteWeapon("pistol")
				else:
					equipped = false
					equipped_text.hide()
					OWNER.slot_pistol_icon.equipped_item = null
					OWNER.slot_pistol_icon.texture = null
					GameManager.weapon_system.DeleteWeapon("pistol",_is_wipe)
			if not _is_wipe:
				GameManager.weapon_system.CheckWeaponsInInventorySlots()
				GameManager.weapon_system.DrawWeapon("pistol")
			
				
	if keys["type"] == "equipment":
		if keys["slot"] == "belt":
			for b in range(1,4):
				if GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%b) != null and GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%b).equipped:
					if not equipped and GameManager.Gui.InventoryWindow._GetItemInSlot("belt%d"%b).ID == ID:
						_select_item(true)
						return
						
			
			var belt_index = 0
			for belt in OWNER.belt:	
				if not belt.equipped_item and not equipped:
					_equip_item(belt)
					_select_item(true)
					if "max_hp" in keys["on_use"]:
							GameManager.player.AddMaxHp(keys["on_use"]["max_hp"])
					
					if "accuracy" in keys["on_use"]:
						GameManager.Gui.SkillWindow.accuracy += keys["on_use"]["accuracy"] / 100
					
					if "strength" in keys["on_use"]:
							GameManager.Gui.SkillWindow.strenght += keys["on_use"]["strength"] / 100
					
					if "armor" in keys["on_use"]:
						GameManager.Gui.SkillWindow.armor += keys["on_use"]["armor"]
					if "weight" in keys["on_use"]:
						GameManager.Gui.InventoryWindow.weight_max += keys["on_use"]["weight"]
						GameManager.Gui.InventoryWindow.UpdateWeight()
					if "rad_resist" in keys["on_use"]:
						GameManager.Gui.SkillWindow.radiation_resistance += keys["on_use"]["rad_resist"]
					if "anomaly_resist" in keys["on_use"]:
						GameManager.Gui.SkillWindow.anomaly_resistance += keys["on_use"]["anomaly_resist"]
							
					if "action" in keys["on_use"]:
						if keys["on_use"]["action"] == "flashlight":
							GameManager.player.flashlight.show()
							
					#print("equiped at %s belt" % str(belt_index))
					GameManager.Gui.belt_ui[belt_index].texture = belt.texture
					belt_index += 1
					
					break
				else:
					belt_index += 1
					if belt.equipped_item == self:
						_select_item(false)
						belt.equipped_item = null
						belt.texture = null
						equipped = false
						_select_item(true)
						equipped_text.hide()
						belt_index -= 1
						if "max_hp" in keys["on_use"]:
							# calc defference percentage between current hp and max hp
							# to keep that percentage when we unequip artefact or another stuff
							# that change our max hp.
							#var hp_percentage_difference : float = 0.0
							#var new_hp_with_difference : float = 0.0
							# if player's health less than max hp, calculate difference. Else - just change max hp
							#if GameManager.player.health < GameManager.player.health_max:
							#	hp_percentage_difference = snappedf(((GameManager.player.health_max - GameManager.player.health) / GameManager.player.health_max) * 100,2)
							#	new_hp_with_difference = snappedf((GameManager.player.health_max - keys["on_use"]["max_hp"]) - (hp_percentage_difference / 100 * (GameManager.player.health_max - keys["on_use"]["max_hp"])),2)
							#	GameManager.player.LowMaxHp(keys["on_use"]["max_hp"])
							#	GameManager.player.SetHealth(snappedf(new_hp_with_difference,2))
							#else:
							GameManager.player.LowMaxHp(keys["on_use"]["max_hp"])
						if "accuracy" in keys["on_use"]:
							GameManager.Gui.SkillWindow.accuracy -= keys["on_use"]["accuracy"] / 100
							
						if "strength" in keys["on_use"]:
							GameManager.Gui.SkillWindow.strenght -= keys["on_use"]["strength"] / 100
						if "weight" in keys["on_use"]:
							GameManager.Gui.InventoryWindow.weight_max -= keys["on_use"]["weight"]
							GameManager.Gui.InventoryWindow.UpdateWeight()
						if "armor" in keys["on_use"]:
							GameManager.Gui.SkillWindow.armor -= keys["on_use"]["armor"]
						if "rad_resist" in keys["on_use"]:
							GameManager.Gui.SkillWindow.radiation_resistance -= keys["on_use"]["rad_resist"]
						if "anomaly_resist" in keys["on_use"]:
							GameManager.Gui.SkillWindow.anomaly_resistance -= keys["on_use"]["anomaly_resist"]
						
						if "action" in keys["on_use"]:
							if keys["on_use"]["action"] == "flashlight":
								GameManager.player.flashlight.hide()
							
						GameManager.Gui.belt_ui[belt_index].texture = null
						break
		if keys["slot"] == "outfit":
			if not equipped:
				_equip_item(OWNER.slot_outfit_icon)
				var icon_rotated : Image = OWNER.slot_outfit_icon.texture.get_image() as Image
				icon_rotated.rotate_90(COUNTERCLOCKWISE)
				OWNER.slot_outfit_icon.texture = ImageTexture.create_from_image(icon_rotated)
				_select_item(true)
				if "armor" in keys["on_use"]:
					GameManager.Gui.SkillWindow.armor += keys["on_use"]["armor"]
				if "weight" in keys["on_use"]:
						GameManager.Gui.InventoryWindow.weight_max += keys["on_use"]["weight"]	
						GameManager.Gui.InventoryWindow.UpdateWeight()
				if "rad_resist" in keys["on_use"]:
					GameManager.Gui.SkillWindow.radiation_resistance += keys["on_use"]["rad_resist"]
				if "anomaly_resist" in keys["on_use"]:
					GameManager.Gui.SkillWindow.anomaly_resistance += keys["on_use"]["anomaly_resist"]
			else:
				_select_item(false)
				equipped = false
				if "armor" in keys["on_use"]:
					GameManager.Gui.SkillWindow.armor -= keys["on_use"]["armor"]
				if "weight" in keys["on_use"]:
						GameManager.Gui.InventoryWindow.weight_max -= keys["on_use"]["weight"]	
						GameManager.Gui.InventoryWindow.UpdateWeight()
				if "rad_resist" in keys["on_use"]:
					GameManager.Gui.SkillWindow.radiation_resistance -= keys["on_use"]["rad_resist"]
				if "anomaly_resist" in keys["on_use"]:
					GameManager.Gui.SkillWindow.anomaly_resistance -= keys["on_use"]["anomaly_resist"]
				_select_item(true)
				equipped_text.hide()
				OWNER.slot_outfit_icon.equipped_item = null
				OWNER.slot_outfit_icon.texture = null
				
	GameManager.on_item_used.emit(self)

func _on_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if OWNER is LootWindow:
					# IF WE CLICK ONLY ON ITEMS IN BOX SIDE
					if get_parent().name == "items_list":
						if OS.has_feature("windows"):
						# we check if future weight will be enough to take it
							var _weight_calculator = GameManager.Gui.InventoryWindow.weight + weight
							
							if _weight_calculator < GameManager.Gui.InventoryWindow.weight_max:
									GameManager.Gui.InventoryWindow.AddItem(ID)
									OWNER._clear_selection_texts()
									OWNER.emit_signal("on_item_took",ID)
									OWNER.on_item_took_callback(ID)
									OWNER.TakeItemFromLoot(ID)
									GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
							else:
								_select_item(false)
								await get_tree().process_frame
								GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
								
						if OS.has_feature("mobile"):
							if OWNER.can_be_looted:
								if not selected:
									_select_item(true)
									return
								else:
									#var _weight_calculator = GameManager.Gui.InventoryWindow.weight + weight
								
									#if _weight_calculator < GameManager.Gui.InventoryWindow.weight_max:
										#print("take loot mobile")
										#OWNER.TakeItemFromLoot(ID)
										#OWNER.can_be_looted = false
										_select_item(false)
										#return
									#else:
									#	_select_item(false)
									#	await get_tree().process_frame
									#	GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
						#print(GameManager.Gui.InventoryWindow.weight)
					# IF WE CLICK ONLY ON ITEMS IN PLAYER'S SIDE
					if get_parent().name == "items_list_player":
						if OS.has_feature("windows"):
							if not equipped:
								GameManager.Gui.InventoryWindow.DeleteItem(instance_id)
								OWNER.AddItemToLoot(ID)
								OWNER.on_item_send_callback(ID)
								GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
						if OS.has_feature("mobile"):
							if not selected:
								_select_item(true)
								return
							else:
								if not equipped:
									#GameManager.Gui.InventoryWindow.DeleteItem(instance_id)
									#OWNER.AddItemToLoot(ID)
									#OWNER.on_item_send_callback(ID)
									#GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
									_select_item(false)
					#OWNER.emit_signal("on_item_delete")
				if OS.has_feature("mobile"):
					if OWNER is Inventory:
						if not selected:
							OWNER.ClearAllSelections()
							_select_item(true)
							return
						else:
							UseItem()
							GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
							_select_item(false)
							OWNER.ClearAllSelections()
						#await get_tree().create_timer(0.1).timeout
						#GameManager.Gui.UpdateHUDAmounts()
						#print("+ Був використаний предмет [%s]!\n\n" % ID)
					# if current window is Trading and item ID not in blacklist
					# we can sell this item to trader 
					if OWNER is TradingSystem and ID not in OWNER.traders["dont_want_to_buy"]:
						# BUY
						if get_parent().name == "trader_items_list":
							if not selected:
								OWNER.clear_all_selections()
								_clear_selection_texts()
								_select_item(true)
								return
							else:
							# if we got enough money
								if GameManager.player.money >= keys["price"]:
									# del item weight
									# but before we check if future weight will be enough to take it
									var _weight_calculator = GameManager.Gui.InventoryWindow.weight + weight
									if _weight_calculator < GameManager.Gui.InventoryWindow.weight_max:
										GameManager.Gui.InventoryWindow.AddItem(ID)
										GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
										GameManager.player.LowMoney(keys["price"])
									else:
										GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
								else:
									GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.no.money"))
								_select_item(false)
						# SELL
						if get_parent().name == "player_items_list":
							if not selected:
								OWNER.clear_all_selections()
								_clear_selection_texts()
								_select_item(true)
								return
							else:
								if ID not in OWNER.traders["dont_want_to_buy"] and not GameManager.Gui.InventoryWindow.FindItem(instance_id).equipped:
									if stack > 1:
										GameManager.Gui.InventoryWindow.FindItem(instance_id).MinusStack(1)
									else:
										GameManager.Gui.InventoryWindow.DeleteItem(instance_id)
									GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
									GameManager.player.AddMoney(int(keys["price"])/2 if not GameManager.casual_gameplay else int(keys["price"]))
						OWNER._update_money()
						OWNER._update_bags()
					elif OWNER is TradingSystem and ID in OWNER.traders["dont_want_to_buy"]:
						if not selected:
							OWNER.clear_all_selections()
							_clear_selection_texts()
							_select_item(true)
							return
						else:
							_clear_selection_texts()
							_select_item(false)
							
			if OS.has_feature("windows"):
				if event.double_click:
					if OWNER is Inventory:
						UseItem()
						GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
						#await get_tree().create_timer(0.1).timeout
						#GameManager.Gui.UpdateHUDAmounts()
						#print("+ Був використаний предмет [%s]!\n\n" % ID)
					# if current window is Trading and item ID not in blacklist
					# we can sell this item to trader 
					if OWNER is TradingSystem and ID not in OWNER.traders["dont_want_to_buy"]:
						# BUY
						if get_parent().name == "trader_items_list":
							# if we got enough money
							if GameManager.player.money >= keys["price"]:
								# del item weight
								# but before we check if future weight will be enough to take it
								var _weight_calculator = GameManager.Gui.InventoryWindow.weight + weight
								if _weight_calculator < GameManager.Gui.InventoryWindow.weight_max:
									GameManager.Gui.InventoryWindow.AddItem(ID)
									GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
									GameManager.player.LowMoney(keys["price"])
								else:
									GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.maybe.no.weight"))
							else:
								GameManager.Gui.ShowTradingMessage("[center]"+Lang.translate("message.no.money"))
						# SELL
						if get_parent().name == "player_items_list":
							if ID not in OWNER.traders["dont_want_to_buy"] and not GameManager.Gui.InventoryWindow.FindItem(instance_id).equipped:
								if stack > 1:
									GameManager.Gui.InventoryWindow.FindItem(instance_id).MinusStack(1)
								else:
									GameManager.Gui.InventoryWindow.DeleteItem(instance_id)
								GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_item_use"])
								GameManager.player.AddMoney(int(keys["price"])/2 if not GameManager.casual_gameplay else int(keys["price"]))
						OWNER._update_money()
						OWNER._update_bags()

func _on_mouse_entered():
	_select_item(true)


func _on_mouse_exited():
	_select_item(false)
