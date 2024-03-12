class_name DialogueSystem extends Control

@onready var npc_name : Label = $npc_name
@onready var npc_text : RichTextLabel = $npc_text_scroll/npc_text_vbox/npc_text
@onready var npc_text_scroll : ScrollContainer = $npc_text_scroll
@onready var player_answer_list = $answer_scroll/player_answers_list
var player_answer_template = preload("res://engine_objects/player_answer.tscn")
var ID : String = ""
var _scroll_timer = 2.0
var _scroll_timer_delay = 1.5

signal dialogue_started
signal dialogue_ended

var dialogue_json

func StartDialogue(id:String, talker_name : String = "",first_replic_id = ""):
	if GameManager.Gui.InventoryWindow.IsOpened():
		GameManager.Gui.InventoryWindow.Close()
		GameManager.pause = false
	ID = id
	dialogue_json = Utility.read_json("assets/dialogues/%s.json" % id)
	# if we have custom first replic ID
	if not first_replic_id.is_empty():
		dialogue_json["start_dialogue"] = first_replic_id
		
	npc_name.text = Lang.translate(talker_name)
	emit_signal("dialogue_started",id)
	
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_dialogue_open"])
	Open()

func _ready():
	var t = GameManager.Wait(0.1) as Timer
	await t.timeout
	t.queue_free()
	#StartDialogue("tutorial_info","Tutorial")

func _clear():
	for answer in player_answer_list.get_children():
		answer.queue_free()
	npc_text.text = ""

func choose_player_replic(index:int):
	for answer in range(0,player_answer_list.get_children().size()):
		if index == answer:
			player_answer_list.get_child(answer).answer_pressed()
			break

func _input(event):
	if IsOpened():
		if Input.is_action_just_pressed("1"):
			choose_player_replic(0)
		if Input.is_action_just_pressed("2"):
			choose_player_replic(1)
		if Input.is_action_just_pressed("3"):
			choose_player_replic(2)
		if Input.is_action_just_pressed("4"):
			choose_player_replic(3)
		if Input.is_action_just_pressed("5"):
			choose_player_replic(4)
		if Input.is_action_just_pressed("6"):
			choose_player_replic(5)
		if Input.is_action_just_pressed("7"):
			choose_player_replic(6)
		if Input.is_action_just_pressed("8"):
			choose_player_replic(7)
		if Input.is_action_just_pressed("9"):
			choose_player_replic(8)

func _process(delta):
	if IsOpened():
		_scroll_timer -= delta
		if _scroll_timer <= 0:
			npc_text_scroll.scroll_vertical += 8
			_scroll_timer = _scroll_timer_delay

func _change_replic(replic_id : String):
	_clear()
	#if dialogue_json == null: BugTrap.Crash("There's no dialogue file with %s ID!" % ID)
	
	var answer_index : int = 1
	
	npc_text.text = "- "+Lang.translate(dialogue_json["dialogues"][replic_id]["text"])
	for player_answer in dialogue_json["dialogues"][replic_id]["answers"]:
		#player_answer)
		if "condition_has_not" in player_answer:
			#print("+ Знайдено кондішн на відсутність ключа в репліці [%s]" % replic_id)
			if GameManager.DontHasEventKey(player_answer["condition_has_not"]):
				#print("+ Ключа не виявлено, можна додавати репліку в ліст")
				pass
			else:
				#print("+ Ключ виявлено, стоп!")
				continue
				
		if "condition_has" in player_answer:
			if GameManager.HasEventKey(player_answer["condition_has"]):
				pass
			else:
				continue
				
		if "condition_has_items" in player_answer:
			var items_found = 0
			for itm in player_answer["condition_has_items"]:
				if GameManager.Gui.InventoryWindow.Find(itm):
					#print("Found needed item!")
					items_found += 1
				if items_found == player_answer["condition_has_items"].size():
					pass
					
			if items_found != player_answer["condition_has_items"].size():
				continue
				
		if "condition_has_not_items" in player_answer:
			var items_not_found = 0
			for itm in player_answer["condition_has_not_items"]:
				if not GameManager.Gui.InventoryWindow.Find(itm):
					#print("Found needed item!")
					items_not_found += 1
				if items_not_found == player_answer["condition_has_not_items"].size():
					pass
					
			if items_not_found != player_answer["condition_has_not_items"].size():
				continue
				
		if "condition_money" in player_answer:
			if GameManager.player.money >= player_answer["condition_money"]:
				pass
			else:
				continue
				
		if "condition_equiped" in player_answer:
			var items_equipped = 0
			for itm in player_answer["condition_equiped"]:
				if GameManager.Gui.InventoryWindow.Find(itm).equipped:
					#print("Found needed item equipped!")
					items_equipped += 1
				if items_equipped == player_answer["condition_equiped"].size():
					pass
				
		var new_answer = player_answer_template.instantiate()
		new_answer.name = "answer_%s" % str(new_answer.get_instance_id())
		new_answer.keys = player_answer
		new_answer.text = "%d. %s" % [answer_index,Lang.translate(player_answer["text"])]		
		player_answer_list.add_child(new_answer)
		answer_index += 1
		

func _player_answer_clicked(keys : Dictionary):
	if "action" in keys:
		if "add_e_key" in keys['action']:
			for ekey in keys['action']["add_e_key"]:
				#print("+ Був доданий EventKey -> %s" % ekey)
				GameManager.AddEventKey(ekey)
		if "del_e_key" in keys['action']:
			for ekey in keys['action']["del_e_key"]:
				#print("+ Був видалений EventKey -> %s" % ekey)
				GameManager.DeleteEventKey(ekey)
		if "add_money" in keys['action']:
			GameManager.player.AddMoney(keys['action']["add_money"])
		if "del_money" in keys['action']:
			GameManager.player.LowMoney(keys['action']["del_money"])
			#print("money deleted!")
		if "del_item" in keys["action"]:
			for itm in keys['action']["del_item"]:
				GameManager.Gui.InventoryWindow.Find(itm).DeleteItem()
		if "add_item" in keys['action']:
			for itm in keys['action']["add_item"]:
				GameManager.Gui.InventoryWindow.AddItem(itm)
		if "add_quest" in keys["action"]:
			for quest in keys["action"]["add_quest"]:
				GameManager.AddQuestJson(quest)
	if keys["go_to"] == "close_dialog":
		var t = GameManager.Wait(0.1) as Timer
		await t.timeout
		t.queue_free()
		emit_signal("dialogue_ended",ID)
		ID = ""
		Close()
	elif keys["go_to"] == "close_game":
		get_tree().quit()
	else:
		_change_replic(keys["go_to"])

func Open():
	_change_replic(dialogue_json["start_dialogue"])
	self.show()
	if GameManager.Gui.InventoryWindow.IsOpened():
		Close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
# Close inventory func
func Close():
	self.hide()
	_clear()
	if not GameManager.Gui.death_screen.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Check if inventory is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false
