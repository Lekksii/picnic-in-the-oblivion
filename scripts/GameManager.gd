## Game manager that control mostly all sides of gameplay, level loading, changin levels, handling all that staff
extends Node

var _psx_unlit_mat = preload("res://shaders/base_unlit.tres")
var _psx_lit_mat = preload("res://shaders/base_lit.tres")
var _psx_unlit_mat_double = preload("res://shaders/base_unlit_doublesided.tres")
var _psx_lit_mat_double = preload("res://shaders/base_lit_doublesided.tres")
var _mat_invisible = preload("res://ingame_materials/standard_invisible.tres")
var _base_mat = preload("res://ingame_materials/pito_3d_mat.tres")
var _base_mat_emission = preload("res://ingame_materials/pito_3d_emission_mat.tres")
var _sounds_collector = []

var app_dir
@onready var Gui : GUI
@onready var World : Node3D
@onready var GameProcess : Game
var is_game_ready = false
@onready var level_sky : MeshInstance3D
@onready var outsky_color : CSGSphere3D
@onready var player : Player
@onready var effect_cam
@onready var effect_cam_head
@onready var ambient_system : AmbientSystem

# SOME CONDITIONAL VARIABLES AND GAMEPLAY OPTIONS
var level_is_safe = false #used for saving system (save game in safe level whenever we close pause/inv/pda etc)
var _spawn_menu = true #eables/disables spawn menu availibility
var casual_gameplay = false #difficulty level, false - normal, true - easy
var enemy_accuracy_always = false # enemy always hit player without missing
var moving_sky_shader = true #used for levels skyboxes, enabling/disabling sky animation
var corpse_cleaner = false #used for cleaning corpses on level after enemy death
var volumetric_fog = false
var first_rad_damage = true

var game_version = 1.2
var game_build = "[color=28be38]260624[/color]" #"[color=28be38]%02d%02d%s[/color]" % [Time.get_date_dict_from_system().day, Time.get_date_dict_from_system().month, str(Time.get_date_dict_from_system().year).trim_prefix("20")]
var game_version_suffix = "| hotfix [color=4a739f]3[/color]" if OS.has_feature("windows") else "| [color=33e546]Web Demo[/color]"
var editor_mode = false
var current_level_id = ""
var current_level
var waypoints : Path3D
var loading_timer = randf_range(1.0,3.0)
var sky_speed = Vector2(0.25,0)
var pause : bool = false
var level_debug = false
var _level_loaded = false

# give player dev features (such as copy position/rotation on V/B)
var developer_mode = false

# Start game from main menu
var main_menu = false
var show_splash = false

#########################
### GAMEPLAY VARIABLES
#########################

var aim_assist = true
var ai_ignore = false
var show_fps = false
var godmode = false

#########################

var loading_autoclose = true
var pda_enabled = false
var look_at_npc = false
var looked_npc = null
var obj_player_looked = null
var reset_lerp_player_rotation = false

var weapon_system : WeaponSystem
var event_keys : Array
var quests : Dictionary = {}
var in_eyezone = false
var autoshoot_timer = randf_range(0.1,0.8)

## Emits when player change level
signal on_level_changed
## Emits when player looked at NPC
signal looked_at_npc
## Emits when player kill NPC
signal on_npc_kill
## Emits when player recieve quest
signal on_quest_add
## Emits when player completed the quest
signal on_quest_complete
## Emits when dialogue closed
signal on_dialogue_end
## Emits when player recieve event key
signal on_event_key_add
## Emits when player use transition zone (door)
signal on_door_used
## Emits when npc finished animation that was played before
signal on_npc_animation_finished
## Emits when item was used
signal on_item_used
## Emits when player start talking with NPC
signal on_npc_talk

signal npc_loaded
var start_loading_from_file : bool = false

signal on_game_ready
signal on_trading_message_ok

# JSON files
var loot_json
var items_json
var weapons_json
var player_json
var npc_json
var npc_enemy_json
var traders_json
var map_json
var waypoints_json
var quests_json
var sfx_manager_json

signal assets_folder_loaded
# ------------ EDITOR
var editor_mouse_mode = "selection"
var editor_level_objects = []

func _enter_tree():
	if OS.has_feature('standalone'):
		app_dir = OS.get_executable_path().replace('picnic.exe',"")
	elif OS.has_feature('mobile'):
		app_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)+"/Android/data/com.leksii.pito/files/"
	else:
		app_dir = "res://"
	
	#await assets_folder_loaded
	#FileAccess.open("user://test.txt",FileAccess.WRITE)
	print("SYSTEM PATH: "+ OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP))
	print("USER DATA PATH: "+ OS.get_user_data_dir())
	#for folder in DirAccess.get_directories_at("res://assets/"):
	#	folders[folder] = {}
	#for f in folders.keys():
	#	folders[f]=DirAccess.get_files_at("res://assets/"+f+"/")
	
	#print(folders)
	print("App Dir is: "+app_dir+"\n")
	
	
	if !DirAccess.dir_exists_absolute(app_dir+"assets" if OS.has_feature('standalone') else app_dir+"/assets"):
		print("[GAME LOADING ERROR]: THIS IS YOUR PROBLEM!!!")
		print("[GAME LOADING ERROR]: >>>>> CANNOT FIND ASSETS FOLDER NEAR 'PICNIC.EXE' FILE!!!")
		print("[GAME LOADING ERROR]: PLEASE, PUT ASSETS FOLDER BACK!!!\n\n\n\n\n\n\n\n")
		BugTrap.Crash("[color=orange]Game can't find asset directory at path:[/color] \n%s" % app_dir+"assets","game app can't find \"assets\" folder near itself.")
		#get_tree().quit()
		return

func _ready():

	#if FileAccess.file_exists(app_dir+"logs.txt"):
		#var logs = FileAccess.open(app_dir+"logs.txt",FileAccess.WRITE)
		#logs.store_string("Game running!\n------------------------------")
		#logs.close()
	GameAPI.RunOutsideScript("p_app").game_init()
	
	GameProcess = get_node("/root/Game") as Game
	#print(GUI)
	Gui = get_node("/root/Game/CanvasLayer/GUI") as GUI
	await get_tree().process_frame
	
	#print(GUI)
	show_loading()
	is_game_ready = true
	game_ready()
	hide_loading()

func _editor_ready():
	pass
	#Gui.crosshair.visible = false
	#Gui.GetEditorElement("top/level_name").text = "-> level/%s" % current_level_id
	
func _input(event):
	if OS.has_feature("mobile"):
		if is_game_ready and current_level != null:
				if event is InputEventScreenTouch:
					if event.double_tap:
						if Gui.crosshair.texture == Gui.crosshair_use_texture:
							print("interaction double tap")							
							Input.action_press("use")
							await get_tree().create_timer(0.1).timeout
							Input.action_release("use")
							return
						else:
							print("reload double tap")
							call_reload()
							return
						
	
func find_object(object_name):
	for obj in editor_level_objects:
		if obj.name == object_name:
			return obj

func _editor_update(_delta):
	pass

func find_sound_in_collector(fname:String) -> AudioStreamPlayer:
	for snd in _sounds_collector:
		if snd.name == fname:
			return snd as AudioStreamPlayer
	return null

func PlaySFXLoaded(file_name:String,volume:float = -4.0):
	if self.has_node(file_name):
		var sounds_collector = player.get_node("Head/PlayerCamera/Sounds")
		var sfx = player.get_node("Head/PlayerCamera/sfx1").duplicate() as AudioStreamPlayer
		sounds_collector.add_child(sfx)
		sfx.volume_db = volume
		sfx.set_stream(find_sound_in_collector(file_name).stream)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
		return sfx

## Play SFX sound using only file name
func PlaySFX(path,volume: float = -4.0):
	var sounds_collector = player.get_node("Head/PlayerCamera/Sounds")
	var sfx = player.get_node("Head/PlayerCamera/sfx1").duplicate() as AudioStreamPlayer
	sounds_collector.add_child(sfx)
	sfx.volume_db = volume
	if FileAccess.file_exists(app_dir+"assets/sounds/%s.wav" % path):
		player.PlayAudio(sfx,"assets/sounds/%s.wav" % path)
	elif FileAccess.file_exists(app_dir+"assets/sounds/%s.mp3" % path):
		player.PlayAudio(sfx,"assets/sounds/%s.mp3" % path)
	else:
		BugTrap.Crash("Can't find sound: assets/sounds/%s" % path)
	sfx.finished.connect(sfx.queue_free)

func scan_folders(path):
	return DirAccess.get_directories_at(app_dir+path)

#region GameReady init
# Called when the node enters the scene tree for the first time.
func game_ready():
	#ProjectSettings.set_setting("debug/file_logging/log_path",app_dir+"GameLog.log")
	World = get_node("/root/Game/sv/EffectDither/World")
	var dirs = scan_folders("assets/sounds/")
	var sounds = []
	var ready_to_use_sounds = []
	var audio_loader = AudioLoader.new()
	for dir in range(-1,dirs.size()):
		if dir == -1:
			sounds = DirAccess.get_files_at(app_dir+"assets/sounds/")
			for sound_file in sounds:
				if not sound_file.contains(".import"):
					ready_to_use_sounds.append(sound_file.split('.')[0])
		else:
			sounds = DirAccess.get_files_at(app_dir+"assets/sounds/"+dirs[dir]+"/")
			for sound_file in sounds:
				if not sound_file.contains(".import"):
					ready_to_use_sounds.append(dirs[dir]+"/"+sound_file.split('.')[0])
	#print(ready_to_use_sounds)
	
	for snd in ready_to_use_sounds:
		var stream = AudioStreamPlayer.new()
		if snd.contains('/'):
			stream.name = snd.split('/')[1]
		else:
			stream.name = snd
		
		if FileAccess.file_exists(app_dir+"assets/sounds/%s.wav" % snd):
			stream.set_stream(audio_loader.loadfile(GameManager.app_dir+"assets/sounds/%s.wav" % snd))
		elif FileAccess.file_exists(app_dir+"assets/sounds/%s.mp3" % snd):
			stream.set_stream(audio_loader.loadfile(GameManager.app_dir+"assets/sounds/%s.mp3" % snd))			
		else:
			BugTrap.Crash("Can't read sound: assets/sounds/%s" % snd)
		self.add_child(stream)
		_sounds_collector.append(stream)
		
	print("GameManager sounds collector: %d" % get_child_count())
	# ---------------------------- WHERE GAME CAN BE RUN ---------------------------
	# Set game wold
	loot_json = Utility.read_json("assets/gameplay/loot_containers.json")
	items_json = Utility.read_json("assets/gameplay/items.json")
	weapons_json = Utility.read_json("assets/gameplay/weapons.json")
	player_json = Utility.read_json("assets/creatures/player.json")
	npc_json = Utility.read_json("assets/creatures/characters.json")
	npc_enemy_json = Utility.read_json("assets/creatures/enemy.json")
	traders_json = Utility.read_json("assets/creatures/traders.json")
	map_json = Utility.read_json("assets/gameplay/pda.json")
	waypoints_json = Utility.read_json("assets/gameplay/waypoints.json")
	quests_json = Utility.read_json("assets/gameplay/quests.json")
	sfx_manager_json = Utility.read_json("assets/gameplay/sfx_manager.json")
	
	player = World.get_node("Player")
	#effect_cam = World.get_node("moving_effector/EffectCamera")
	#effect_cam_head = World.get_node("moving_effector")
	waypoints = World.get_node("waypoints") as Path3D
	weapon_system = WeaponSystem.new()
	weapon_system.shot.connect(on_weapon_shot)
	# Set outsky color for level color
	outsky_color = World.get_node("outsky")
	looked_at_npc.connect(on_npc_looked)
	ambient_system = World.get_node("AmbientSystem")
	
	if not main_menu:
		if Gui.main_menu.visible:
			HideMainMenu()
			
		player.LoadPlayerProfile()
		#Gui.DialogueWindow.StartDialogue("tutorial_info")
		#Gui.MapWindow.AddMarker("village_marker")
		await get_tree().create_timer(0.1).timeout
		
		# SET GAME INIT
		Gui.InventoryWindow._game_ready_inventory()
		weapon_system._game_ready()
		weapon_system.UpdateAmmo()
		#await get_tree().create_timer(0.2).timeout
		LoadGameLevel(player_json["start_level"])
		#Gui.LoadHelpTipJson("radiation_tip")
		#AddQuest("test","Test Quest",0,[])
	else:
		ShowMainMenu()
		# if we don't show splash - play music
		# else if splash is on - music will play after splashes ends
		if not show_splash:
			GameManager.player.PlayMusic("assets/sounds/mm_music.wav")
			
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	on_game_ready.emit()
#endregion

func LoadGameLevel(level_id : String, silent : bool = false):
	if DirAccess.dir_exists_absolute(app_dir+"assets/levels/%s" % level_id):
		change_level(level_id, silent)
		
	if FileAccess.file_exists(app_dir+"assets/levels/%s.tscn" % level_id) or \
	FileAccess.file_exists(app_dir+"assets/levels/%s.scn" % level_id) or \
	FileAccess.file_exists(app_dir+"assets/levels/%s.res" % level_id):
		load_level_from_file(level_id,silent)

func ShowPDA(value):
	pda_enabled = value
	if pda_enabled:
		Gui.pda_icon.show()
		Gui.pda_icon.get_child(0).play("blink")
	else:
		Gui.pda_icon.hide()

func ShowMainMenu() -> void:
	Gui.main_menu.show()
	
func HideMainMenu() -> void:
	Gui.main_menu.hide()

func GetQuestsIDs():
	var _list = []
	for q in quests:
		_list.append(q)
	return _list
	
func _key_pressed(action : String):
	return Input.is_action_just_pressed(action)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	#if Input.is_key_pressed(KEY_X) and not Gui.ConsoleWindow.visible:
		#get_tree().quit()
	
	if is_game_ready and not GameManager.player.is_dead:
		
		if Input.is_key_pressed(KEY_V) and developer_mode:
			DisplayServer.clipboard_set("%.2f, %.2f, %.2f" % [player.position.x,player.position.y, player.position.z])
			Gui.ShowMessage("Player's position copied!")
		
		if Input.is_key_pressed(KEY_B) and developer_mode:
			DisplayServer.clipboard_set("%.2f, %.2f, %.2f" % [player.PlayerCamera.rotation.x,player.rotation.y, player.PlayerCamera.rotation.z])
			Gui.ShowMessage("Player's rotation copied!")
		
		if Input.is_key_pressed(KEY_F1) and _spawn_menu and not main_menu and not Gui.final_image.visible:
			if not Gui.SpawnMenuWindow.visible:
				Gui.SpawnMenuWindow.Open()
				
		#if Input.is_key_pressed(KEY_F2):
		#	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		#		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		#	else:
		#		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if Input.is_action_just_pressed("screenshot"):
			print("Screenshot!")
			var t = Time.get_datetime_dict_from_system()
			get_viewport().get_texture().get_image().save_png(GameManager.app_dir+"pito_shot_%d_%02d_%02d_%02d_%02d_%02d.png" % [t.year,t.month,t.day,t.hour,t.minute,t.second])
			PlaySFXLoaded("pda")
		#if Input.(KEY_B):
			#Gui.ShowMessage("Enemy spawned!")
			#create_enemy("stalker","range_zone",Vector3(-0.50, -1.05, -3.84),Vector3(0,180,0))
		
		# Heal Player by medkit
		if Input.is_action_just_released("debug_hit"):
			var med = Gui.InventoryWindow.Find("medkit") as item
			var med_army = Gui.InventoryWindow.Find("medkit_army") as item
			if med:
				print("Found medkit - use it and stop function.")
				med.UseItem()
				return
			if med_army:
				print("Found medkit army - use it and stop function.")				
				med_army.UseItem()
				return
			#player.Hit(1)
		
		if editor_mode: _editor_update(_delta)
		
		_game_update(_delta)

#region Save and Load systems
func SaveGame():
	#print("start saving")
	var save_file = FileAccess.open_encrypted_with_pass(app_dir+"progress.save",FileAccess.WRITE,"pito")
	var data = {
		"_comment":"Oh, look at you, you decoded save file. Keep in mind bro, I do not like this. If game will crash - it is only your fault.",
		"game_version": str(game_version),
		"player":{
			"health": player.health,
			"health_max": player.health_max,
			"money": player.money,
			"max_weight": Gui.InventoryWindow.weight_max,
			"level_id": current_level_id
		},
		"level_is_safe": level_is_safe,
		"event_keys": event_keys,
		"quests": GetQuestsIDs(),
		"first_rad_damage": first_rad_damage,
		"pda_enabled": pda_enabled,
		"inventory": Gui.InventoryWindow.GetAllItemsIDs(),
		"equipped_items": Gui.InventoryWindow.GetAllEquippedItemsIDs(),
		"skills":{
			"level": Gui.SkillWindow.level,
			"level_max": Gui.SkillWindow.level_max,
			"exp": Gui.SkillWindow.current_exp,
			"exp_next": Gui.SkillWindow.next_level_exp,
			"points": Gui.SkillWindow.skill_point,
			"accuracy": Gui.SkillWindow.accuracy,
			"health": Gui.SkillWindow.health_max,
			"strenght": Gui.SkillWindow.strenght,
			"armor": Gui.SkillWindow.armor,
			"rad": Gui.SkillWindow.radiation_resistance,
			"anomaly": Gui.SkillWindow.anomaly_resistance
		},
		"pda":{
			"markers": Gui.MapWindow.GetAllMarkersIDs()
		},
		"weapon_system":{
			"last_equipped_slot": "pistol" if weapon_system.current_weapon == weapon_system.pslot else "rifle",
			"current_weapon_magazine": weapon_system.current_weapon.ammo_mag if weapon_system.current_weapon else "null",
			"current_weapon_id": weapon_system.current_weapon.item_data.ID if weapon_system.current_weapon else "null",
			"slot1_mag": weapon_system.pslot.ammo_mag if weapon_system.pslot else "null",
			"slot2_mag": weapon_system.rslot.ammo_mag if weapon_system.rslot else "null"
		}
	}
	save_file.store_string(Utility.beautify_json(str(data)))
	save_file.close()
	Gui.save_icon.show()
	Gui.save_icon.get_node("pda_anim").play("blink")
	print("Game saved to -> %s \n" % [str(app_dir + "progress.save")])
	await get_tree().create_timer(3).timeout
	Gui.save_icon.get_node("pda_anim").stop()
	Gui.save_icon.hide()
	
func WipePlayerData():
	var data = player_json
	#var quests_data = GameManager.quests_json
	
	player.SetMaxHp(data["start_max_hp"])
	player.SetHealth(player.health_max)
	player.SetMoney(data["start_money"])
		
	Gui.SkillWindow._ResetSkills()
		
	await get_tree().create_timer(0.1).timeout
	
	Gui.InventoryWindow.ResetInventorySystem()
	
	ShowPDA(false)
		
	await get_tree().process_frame
	
	Gui.InventoryWindow.ClearAllSelections()
		
	event_keys.clear()
		
	await get_tree().process_frame
		
	weapon_system.last_magazine_wpn = {}
	weapon_system.pslot = null
	weapon_system.rslot = null
		
	for quest in quests:
		DeleteQuest(quest)
		
	await get_tree().process_frame
	
	Gui.MapWindow.WipeAllMarkers()
	
func LoadGame():
	var save_file = FileAccess.open_encrypted_with_pass(app_dir+"progress.save",FileAccess.READ,"pito")
	#print(save_file.get_as_text())
	if save_file.get_as_text() == null:
		Gui.ShowTradingMessage("[center][img=48]"+app_dir+"assets/ui/save_icn.png[/img]\n \n%s" % [Lang.translate("game.loading.version.problem")])
		return		
	var loaded_data = Utility.read_json_string(save_file.get_as_text())
	await get_tree().process_frame
	Gui.loading_screen.show()
	if loaded_data != null and "game_version" in loaded_data and loaded_data["game_version"] == str(game_version):
		var active_markers = 0
		var camp_markers = 0
		#WipePlayerData()
		await get_tree().process_frame
			
		player.SetMoney(loaded_data["player"]["money"])
		
		await get_tree().process_frame
		
		Gui.loading_screen.hide()
		
		Gui.InventoryWindow.weight_max = 999
		
		for i in loaded_data["inventory"]:
			#print("[LOAD GAME]: Add item %s" % i)
			var itm : item = Gui.InventoryWindow.AddItem(i)
			if itm:
				if loaded_data["equipped_items"].has(i):
					#print("[LOAD GAME]: %s was equipped!" % i)
					itm.UseItem()
			
		await get_tree().create_timer(0.1).timeout
		
		#for use in loaded_data["equipped_items"]:
			#if Gui.InventoryWindow.Find(use):
				#Gui.InventoryWindow.Find(use).UseItem()
				
		weapon_system.DrawWeapon(loaded_data["weapon_system"]["last_equipped_slot"])
		
		await get_tree().process_frame
		
		Gui.InventoryWindow.ClearAllSelections()
		
		first_rad_damage = loaded_data["first_rad_damage"]
		
		#print("Type of = "+ str(typeof(loaded_data["weapon_system"]["current_weapon_magazine"])))
		#print("STRING: %d, FLOAT: %d" % [TYPE_STRING, TYPE_FLOAT])
		if typeof(loaded_data["weapon_system"]["current_weapon_magazine"]) == TYPE_INT:
			weapon_system.current_weapon.ammo_mag = loaded_data["weapon_system"]["current_weapon_magazine"]
		if typeof(loaded_data["weapon_system"]["slot1_mag"]) == TYPE_INT:
			weapon_system.pslot.ammo_mag = loaded_data["weapon_system"]["slot1_mag"]
		if typeof(loaded_data["weapon_system"]["slot2_mag"]) == TYPE_INT:
			weapon_system.rslot.ammo_mag = loaded_data["weapon_system"]["slot2_mag"]
		
		weapon_system.UpdateAmmo()
		
		for e_key in loaded_data["event_keys"]:
			AddEventKeySilently(e_key)
			
		for quest in loaded_data["quests"]:
			AddQuestJson(quest,true)
		
		for marker_id in loaded_data["pda"]["markers"]:
			Gui.MapWindow.AddMarker(marker_id)
		
		for m in Gui.MapWindow.markers:
			if m.keys["type"] == "quest":
				active_markers += 1
			if m.keys["type"] == "camp":
				camp_markers += 1
		
		if active_markers > 0:
			GameManager.Gui.pda_icon.show()
			GameManager.ShowPDA(true)
		else:
			GameManager.Gui.pda_icon.hide()
			
		if camp_markers > 1:
			GameManager.ShowPDA(true)
			GameManager.Gui.pda_icon.hide()
			
		
		
		await get_tree().process_frame
		
		Gui.SkillWindow.level = loaded_data["skills"]["level"]
		Gui.SkillWindow.level_max = loaded_data["skills"]["level_max"]
		Gui.SkillWindow.current_exp = loaded_data["skills"]["exp"]
		Gui.SkillWindow.next_level_exp = loaded_data["skills"]["exp_next"]
		Gui.SkillWindow.skill_point = loaded_data["skills"]["points"]
		Gui.SkillWindow.accuracy = loaded_data["skills"]["accuracy"]
		Gui.SkillWindow.armor = loaded_data["skills"]["armor"]
		Gui.SkillWindow.strenght = loaded_data["skills"]["strenght"]
		
		player.SetMaxHp(snappedf(loaded_data["player"]["health_max"],0))
		player.SetHealth(loaded_data["player"]["health"])
		
		Gui.SkillWindow.radiation_resistance = loaded_data["skills"]["rad"]
		Gui.SkillWindow.anomaly_resistance = loaded_data["skills"]["anomaly"]
		
		Gui.InventoryWindow.weight_max = loaded_data["player"]["max_weight"]
		
		LoadGameLevel(loaded_data["player"]["level_id"],true)
		
		await get_tree().process_frame
		ambient_system.player_on_level.emit(loaded_data["player"]["level_id"])
		
		Gui.SkillWindow._update_skills()		
		
		Gui.MapWindow.SetPlayerSpotbyLevelId(loaded_data["player"]["level_id"])
		
		Gui.MainMenuWindow.hide()
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		if "level_is_safe" in loaded_data:
			level_is_safe = loaded_data["level_is_safe"]
		else:
			BugTrap.Crash("Save file is from older version or corrupted!")
		
		save_file.close()
		#print(Utility.beautify_json(str(loaded_data)))
	else:
		GameManager.main_menu = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Gui.MainMenuWindow.hide()
		Gui.ShowTradingMessage("[center][img=48]"+app_dir+"assets/ui/save_icn.png[/img]\n \n%s\n \n%s - %s\n%s - %s" % [Lang.translate("game.loading.version.problem"),Lang.translate("saved.game.version"),loaded_data["game_version"] if "game_version" in loaded_data else "NO DATA",Lang.translate("current.game.version"),str(game_version)])
		save_file.close()
		await on_trading_message_ok
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if not GameManager.player.music.playing:
			GameManager.player.music.play()
		GameManager.Gui.loading_screen.hide()
		Gui.MainMenuWindow.show()
		
#endregion

func Wait(t : float):
	var tmr = Timer.new()
	tmr.name = "WaitTimer"+str(tmr.get_instance_id())
	get_node("/root/Game/sv/EffectDither/World/Player").add_child(tmr)
	tmr.start(t)
	return tmr

func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()	
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().add_child(mesh_instance)
	
	return mesh_instance

func on_npc_looked(_npc):
	pass

## Checking the wyapoints of transition trigger to walk
## If trigger has it in "waypoints" key:
## $to_this_door -> move camera from it's position forward to the trigger position
## 
## If If trigger has in "waypoints" key ID of waypoint from gameplay/waypoints.json
## and special key starts with "_":
## <waypoint_id>_last_points -> go backward by waypoints and start first point from middle of path
## <waypoint_id>_return -> go backward by waypoints from end of points and finish at trigger position
## <waypoint_id>_back_only_waypoints -> go backward by waypoints from end of points and finish only at last point
func _transition_waypoints_check(hit_obj):
	if hit_obj.keys["waypoints"] and player.global_position.distance_to(hit_obj.global_position) > 2.6:
		# check if there's waypoint path on packed level
		var in_level_wp : Path3D = null
		var curve = Curve3D.new()
		waypoints.curve = curve
		# looking for waypoint path3D in current level
		for lvl_wp in current_level.get_children():
			if lvl_wp is Path3D and lvl_wp.name == hit_obj.keys["waypoints"]:
				in_level_wp = lvl_wp as Path3D

		if waypoints_json:			
			if hit_obj.keys["waypoints"] != "$to_this_door":
				# check waypoints json file for current level waypoints
				_transition_check_waypoints_json(hit_obj,curve)
				# if we didn't found any in the file, then get waypoint
				# from current level (if available)
				if in_level_wp:
					waypoints.curve = in_level_wp.curve.duplicate()
					print(waypoints.curve)
					
				if "last_point_is_end" in hit_obj.keys and hit_obj.keys["last_point_is_end"]:
					player.last_point_pos = waypoints.curve.get_point_position(GameManager.waypoints.curve.point_count-1)
			else:
				curve.add_point(Vector3(hit_obj.position.x,randf_range(1.55,1.77),hit_obj.position.z))
			if HasEventKey("doors.return"):
				player.point = ceili(waypoints.curve.point_count / 2)
				DeleteEventKey("doors.return")
			
			if HasEventKey("doors.return.last"):
				player.point = ceili(waypoints.curve.point_count-1)
				DeleteEventKey("doors.return.last")
			
		await get_tree().create_timer(0.1).timeout
		player.waypoint_end_position = hit_obj
		player.waypoint_walk = true
		player.transition_data = hit_obj.keys
		
		if hit_obj.keys["id"] == "transition_to_level":
			player.waypoint_new_level = hit_obj.keys["level"]
			emit_signal("on_door_used",hit_obj.keys)
	else:
		# Player too close to door
		_transition_low_distance(hit_obj)

## Function that runs when player too close to transition zone
## and moving animation will not be played, player will teleported to 
## transition zone's target position
func _transition_low_distance(hit_obj):
	if hit_obj.keys["id"] == "transition":
		if "target_object" in hit_obj.keys and hit_obj.keys["target_object"] != null:
			player.ChangeRotation(current_level.get_node(hit_obj.keys["target_object"]).rotation_degrees)
			player.ChangePosition(current_level.get_node(hit_obj.keys["target_object"]).position)
		else:
			if "target_rotation" in hit_obj.keys:
				player.ChangeRotation(Vector3(hit_obj.keys["target_rotation"][0],hit_obj.keys["target_rotation"][1],hit_obj.keys["target_rotation"][2]))
			player.ChangePosition(Vector3(hit_obj.keys["target_position"][0],hit_obj.keys["target_position"][1],hit_obj.keys["target_position"][2]))
	if hit_obj.keys["id"] == "transition_to_level":
		LoadGameLevel(hit_obj.keys["level"])
	emit_signal("on_door_used",hit_obj.keys)

func _transition_check_waypoints_json(hit_obj,curve):
	for wp in waypoints_json:
		if wp["level"] == current_level_id:
			if hit_obj.keys["waypoints"].contains("_last_points"):
				var backwards_waypoints = wp["waypoints"][hit_obj.keys["waypoints"].replace('_last_points','')]["list"].duplicate()
				backwards_waypoints.reverse()
				
				for wp_point in backwards_waypoints:
					var pos_x = wp_point["position"][0]
					var pos_y = wp_point["position"][1]
					var pos_z = wp_point["position"][2]
					curve.add_point(Vector3(pos_x,pos_y,pos_z))
				
				player.point = ceili(waypoints.curve.point_count / 2)
			elif hit_obj.keys["waypoints"].contains("_return"):
				var backwards_waypoints = wp["waypoints"][hit_obj.keys["waypoints"].replace('_return','')]["list"].duplicate()
				backwards_waypoints.reverse()
				var y_pos : float = 0
				for wp_point in backwards_waypoints:
					var pos_x = wp_point["position"][0]
					var pos_y = wp_point["position"][1]
					y_pos = pos_y
					var pos_z = wp_point["position"][2]
					curve.add_point(Vector3(pos_x,pos_y,pos_z))
				
				curve.add_point(Vector3(hit_obj.position.x,y_pos,hit_obj.position.z))
			elif hit_obj.keys["waypoints"].contains("_back_only_waypoints"):
				var backwards_waypoints = wp["waypoints"][hit_obj.keys["waypoints"].replace('_back_only_waypoints','')]["list"].duplicate()
				backwards_waypoints.reverse()
				var y_pos : float = 0
				for wp_point in backwards_waypoints:
					var pos_x = wp_point["position"][0]
					var pos_y = wp_point["position"][1]
					y_pos = pos_y
					var pos_z = wp_point["position"][2]
					curve.add_point(Vector3(pos_x,pos_y,pos_z))
			else:
				for wp_point in wp["waypoints"][hit_obj.keys["waypoints"]]["list"]:
					var pos_x = wp_point["position"][0]
					var pos_y = wp_point["position"][1]
					var pos_z = wp_point["position"][2]
					#var rot_x = wp_point["rotation"][0]
					#var rot_y = wp_point["rotation"][1]
					#var rot_z = wp_point["rotation"][2]
					curve.add_point(Vector3(pos_x,pos_y,pos_z))
					#curve.set_point_tilt(curve.point_count-1,-rot_y)

func _transition_conditions(hit_obj):
	if "condition" in hit_obj.keys:
		#print("has condition key")
		if HasEventKey(hit_obj.keys["condition"]):
			#print("has e-key what we need")
			pass
		else:
			#print("dont has e-key what we need")
			return
	else:
		pass
	if "condition_not" in hit_obj.keys:
		if DontHasEventKey(hit_obj.keys["condition_not"]):
			pass
		else:
			return
	else:
		pass
#region Process/Raycasting/Shooting/Controls

# GAME MAIN LOOP
func _game_update(_delta):
	# close loading screen
	if Gui.loading_screen.visible and loading_autoclose and _level_loaded:
		#loading_timer -= 1 * _delta
		#if loading_timer <= 0:
		Gui.loading_screen.hide()
			#loading_timer = randf_range(1.0,3.0)
	
	if player.raycast.is_colliding() and player.raycast.get_collider() and not pause:
		var hit_obj = player.raycast.get_collider().get_parent()
		#print(hit_obj)
		
		# IF LOOK AT ENEMY
		if hit_obj is BONE_COLLISION and hit_obj.npc_obj is NPC and hit_obj.npc_obj.is_hostile:
			#Gui.crosshair.modulate = Color.RED
			if not hit_obj.npc_obj.is_dead:
				var a = hit_obj.npc_obj.backpack.global_transform.origin
				#var b = player.global_transform.origin
				if aim_assist and hit_obj.npc_obj.is_attack:
					player.FakeHead.look_at(a)
					player.PlayerHead.rotation.y = lerp_angle(player.PlayerHead.rotation.y,player.FakeHead.rotation.y + player.PlayerHead.rotation.y,_delta * 8 if OS.has_feature("windows") else 1)
				# AUTOFIRE FOR MOBILE VERSION
				if OS.has_feature("mobile"):
					if weapon_system != null:
						if weapon_system.current_weapon.ammo_mag >= 1:
							#print("autoshoot timeout!")
							if weapon_system.current_weapon != null:
									weapon_system.Shoot()
						else:
							Input.action_press("reload")
							Input.action_release("reload")
						
					
		elif hit_obj != BONE_COLLISION:
			Gui.crosshair.modulate = Color.WHITE
		# Changing crosshair when interract and if obj not block
		if hit_obj is level_object and "id" in hit_obj.keys and hit_obj.keys["id"] != "block" and hit_obj.visible:
			obj_player_looked = hit_obj
			if player.current_eyezone and player.current_eyezone.enemies.size() == 0 or player.current_eyezone == null or ai_ignore:
				# if no scoping
				if not weapon_system.is_scoping:
					Gui.PressF(true)
					# if holds weapon
					if weapon_system.current_weapon:
						Gui.crosshair.texture = Gui.crosshair_use_texture
					else:
						Gui.crosshair.texture = Gui.crosshair_use_texture
					
					if hit_obj.keys["id"] == "transition" or hit_obj.keys["id"] == "transition_to_level":
						if "condition" in hit_obj.keys:
							if HasEventKey(hit_obj.keys["condition"]):
								Gui.crosshair.texture = Gui.crosshair_use_texture
							else:
								Gui.crosshair.texture = Gui.crosshair_lock_texture
								Gui.PressF(false)
						
						if "condition_not" in hit_obj.keys:
							if HasEventKey(hit_obj.keys["condition_not"]):
								Gui.crosshair.texture = Gui.crosshair_use_texture
							else:
								Gui.crosshair.texture = Gui.crosshair_lock_texture
								Gui.PressF(false)
			else:
				Gui.PressF(false)
				if not weapon_system.is_scoping:
					# if holds weapon
					if weapon_system.current_weapon:
						Gui.crosshair.texture = Gui.crosshair_gun_texture
					else:
						Gui.crosshair.texture = Gui.crosshair_use_texture
						
		if hit_obj is level_object and "id" not in hit_obj.keys:
			Gui.PressF(false)
			if not weapon_system.is_scoping:
				
					# if holds weapon
				if weapon_system.current_weapon:
					Gui.crosshair.texture = Gui.crosshair_gun_texture
				else:
					Gui.crosshair.texture = Gui.crosshair_use_texture
		# if have ID and its block
		if hit_obj is level_object and "id" in hit_obj.keys and hit_obj.keys["id"] == "block":
			Gui.PressF(false)
			# if player in eyezone or not but it has no enemies - can interact
			if player.current_eyezone and player.current_eyezone.enemies.size() == 0 or player.current_eyezone == null or ai_ignore:
				# if no scoping
				if not weapon_system.is_scoping:
					# if holds weapon
					if weapon_system.current_weapon:
						Gui.crosshair.texture = Gui.crosshair_gun_texture
					else:
						Gui.crosshair.texture = Gui.crosshair_use_texture
			else:
				if weapon_system.current_weapon:
						Gui.crosshair.texture = Gui.crosshair_gun_texture
				else:
					Gui.crosshair.texture = Gui.crosshair_use_texture
			
		if hit_obj is level_object and hit_obj.keys or hit_obj is BONE_COLLISION and (hit_obj.npc_obj is NPC and not hit_obj.npc_obj.is_hostile and hit_obj.npc_obj.profile):
			
			if not weapon_system.is_scoping:
				
				if hit_obj is BONE_COLLISION:
					if hit_obj.npc_obj is NPC and not hit_obj.npc_obj.is_hostile and (player.current_eyezone and player.current_eyezone.enemies.size() == 0 or player.current_eyezone == null or ai_ignore) and hit_obj.npc_obj.can_talk:
						# Get name of NPC
						Gui.PressF(true)
						Gui.show_hint(Lang.translate(hit_obj.npc_obj.profile["name"]))
						look_at_npc = true
						looked_npc = hit_obj.npc_obj
						emit_signal("looked_at_npc",hit_obj.npc_obj)
						Gui.crosshair.texture = Gui.crosshair_use_texture
					else:
						Gui.PressF(false)
						Gui.clear_hint()
						if weapon_system.current_weapon:
							Gui.crosshair.texture = Gui.crosshair_gun_texture
						else:
							Gui.crosshair.texture = Gui.crosshair_use_texture
				else:
					#Gui.PressF(false)
					looked_npc = null
					look_at_npc = false
					Gui.clear_hint()
					#Gui.show_hint(str(snappedf(player.global_position.distance_to(hit_obj.global_position),1)))
					
				if _key_pressed("use") and player.can_use and hit_obj.visible:
					#print("we use")
					if player.current_eyezone and player.current_eyezone.enemies.size() == 0 or player.current_eyezone == null or ai_ignore:
						pass
						
					if player.current_eyezone and player.current_eyezone.enemies.size() > 0 and not ai_ignore:
						return
						
					if hit_obj is level_object:
						#print("its level_object")
					# If current raycasted item isnt NPC
						# if we loot money
						if "id" in hit_obj.keys:
							if hit_obj.keys["id"] == "loot_money":
								player.AddMoney(hit_obj.keys["value"])
								Gui.ShowMessage(str(hit_obj.keys["value"])+"$")
								hit_obj.queue_free()
								GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_loot_money_used"])
								
							# if we change level
							if hit_obj.keys["id"] == "transition_to_level":							
								if "condition" in hit_obj.keys and HasEventKey(hit_obj.keys["condition"]):
									_transition_waypoints_check(hit_obj)
								if "condition" not in hit_obj.keys:
									_transition_waypoints_check(hit_obj)
								if "condition_not" in hit_obj.keys and HasEventKey(hit_obj.keys["condition_not"]):
									_transition_waypoints_check(hit_obj)
							
							if hit_obj.keys["id"] == "usable_area":
								if "event_key" in hit_obj.keys and hit_obj.keys["event_key"]:
									AddEventKey(hit_obj.keys["event_key"])
									GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_usable_zone_used"])
									await get_tree().process_frame
									hit_obj.queue_free()
							
							if hit_obj.keys["id"] == "transition":
								#print("its transition")
								
								if "condition" in hit_obj.keys:
									if HasEventKey(hit_obj.keys["condition"]):
										#print("Has key in transition and has in player")
										_transition_waypoints_check(hit_obj)
								if "condition" not in hit_obj.keys:
									#print("no condition in transition")
									_transition_waypoints_check(hit_obj)
								if "condition_not" in hit_obj.keys and HasEventKey(hit_obj.keys["condition_not"]):
									_transition_waypoints_check(hit_obj)
								#hit_obj.queue_free()
							# if we loot
							if hit_obj.keys["id"] == "loot":
								Gui.Loot.LoadLoot(hit_obj.keys["loot_id"])
								Gui.Loot._loot_id = hit_obj.keys["loot_id"]
								Gui.Loot.Open()
								#if "undestroyable" in hit_obj.keys and hit_obj.keys["undestroyable"]:
								#	pass
								#else:
								#	hit_obj.queue_free()
					# If current collided obj is NPC
					if hit_obj is BONE_COLLISION:
						if hit_obj.npc_obj is NPC and not hit_obj.npc_obj.is_hostile and hit_obj.npc_obj.can_talk:
							if not Gui.DialogueWindow.IsOpened() and not Gui.TradingWindow.IsOpened():
								#print("+ Взаємодія з NPC ["+hit_obj.npc_obj.id+"]")
								if hit_obj.npc_obj.profile["dialogues"] and hit_obj.npc_obj.profile["trader_profile"] == null:
									#Gui.DialogueWindow.StartDialogue()
									for d in hit_obj.npc_obj.profile["dialogues"]:
										# if we have custom start replic
										var custom_start_replic = ""
										if "start_phrase_id" in d and not d["start_phrase_id"].is_empty():
											custom_start_replic = d["start_phrase_id"]
											
										# Если dont_has_event_key ключ существует, а has_event_key не существует
										if "dont_has_event_key" in d and "has_event_key" not in d:
											if DontHasEventKey(d["dont_has_event_key"]):
												#print("+ dont_has_event_key є, але has_event_key немає в діалозі %s" % d["dialogue"])
												Gui.DialogueWindow.StartDialogue(d["dialogue"],hit_obj.npc_obj.profile["name"] if "name" in hit_obj.npc_obj.profile else "",custom_start_replic)
												GameManager.on_npc_talk.emit(hit_obj.npc_obj)
												break
										# Если has_event_key существует и dont_has_event_key существует
										if "has_event_key" in d and "dont_has_event_key" in d:
											if HasEventKey(d["has_event_key"]) and not HasEventKey(d["dont_has_event_key"]):
												#print("+ has_event_key є, але dont_has_event_key немає в діалозі %s" % d["dialogue"])
												Gui.DialogueWindow.StartDialogue(d["dialogue"],hit_obj.npc_obj.profile["name"] if "name" in hit_obj.npc_obj.profile else "",custom_start_replic)
												GameManager.on_npc_talk.emit(hit_obj.npc_obj)
												break
										# Если has_event_key существует, а dont_has_event_key не сущесвтует
										if "has_event_key" in d and "dont_has_event_key" not in d:
											if HasEventKey(d["has_event_key"]):
												#print("+ has_event_key є в діалозі %s" % d["dialogue"])										
												Gui.DialogueWindow.StartDialogue(d["dialogue"],hit_obj.npc_obj.profile["name"] if "name" in hit_obj.npc_obj.profile else "",custom_start_replic)
												GameManager.on_npc_talk.emit(hit_obj.npc_obj)
												break
										# Если has_event_key не существует и dont_has_event_key тоже
										if "has_event_key" not in d and "dont_has_event_key" not in d:
											#print("+ has_event_key немає, але і dont_has_event_key теж немає в діалозі %s" % d["dialogue"])									
											Gui.DialogueWindow.StartDialogue(d["dialogue"],hit_obj.npc_obj.profile["name"] if "name" in hit_obj.npc_obj.profile else "",custom_start_replic)
											GameManager.on_npc_talk.emit(hit_obj.npc_obj)
											break
								if hit_obj.npc_obj.profile["trader_profile"] != null:
									Gui.TradingWindow.Open(hit_obj.npc_obj.profile["trader_profile"])
									GameManager.on_npc_talk.emit(hit_obj.npc_obj)
									GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_trade_open"])
	else:
		if weapon_system.current_weapon:
			Gui.crosshair.texture = Gui.crosshair_gun_texture
		Gui.crosshair.modulate = Color.WHITE
		Gui.clear_hint()
		Gui.PressF(false)
		look_at_npc = false
		obj_player_looked = null
	
	if (Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and pause):
		if Input.is_action_just_pressed("inventory"):
			if Gui.InventoryWindow.visible:
				pause = false
				Gui.InventoryWindow.Close()
				return
			#Gui.SkillWindow.Open()
		
		if Input.is_action_just_pressed("journal"):
			if Gui.JournalWindow.visible:
				pause = false
				Gui.JournalWindow.Close()
				return
			
		if Input.is_action_just_pressed("pda") and pda_enabled:
			if Gui.MapWindow.visible:
				pause = false
				Gui.MapWindow.Close()
				return
			
		if Input.is_action_just_pressed("stats"):
			if Gui.SkillWindow.visible:
				pause = false
				Gui.SkillWindow.Close()
				return
	
		if Gui.SkillWindow.visible and not Gui.SkillWindow.is_open_from_pause:
			if Input.is_action_just_pressed("pause"):
				Gui.PauseWindow.need_open = false
				pause = false
				Gui.SkillWindow.Close()
				return
		elif Gui.MapWindow.visible and not Gui.MapWindow.is_open_from_pause:
			if Input.is_action_just_pressed("pause"):
				Gui.PauseWindow.need_open = false
				pause = false
				Gui.MapWindow.Close()
				return
		elif Gui.JournalWindow.visible and not Gui.JournalWindow.is_open_from_pause:
			if Input.is_action_just_pressed("pause"):
				Gui.PauseWindow.need_open = false
				pause = false
				Gui.JournalWindow.Close()
				return
		elif Gui.InventoryWindow.visible and not Gui.InventoryWindow.is_open_from_pause:
			if Input.is_action_just_pressed("pause"):
				Gui.PauseWindow.need_open = false
				pause = false
				Gui.InventoryWindow.Close()
				return
	
	if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and 
	not main_menu and not pause and not player.waypoint_walk and 
	not weapon_system.is_reloading and not Gui.final_image.visible and 
	not GameProcess.cutscene_camera_movement and not GameProcess.cutscene_camera_rotation and 
	not player.is_cutscene):
		
		if Input.is_action_just_pressed("inventory"):
			if not Gui.InventoryWindow.visible:
				pause = true
				Gui.InventoryWindow.Open()
				Gui.InventoryWindow.is_open_from_pause = false
				return
			#Gui.SkillWindow.Open()
		
		if Input.is_action_just_pressed("journal"):
			pause = true
			Gui.JournalWindow.Open()
			Gui.JournalWindow.is_open_from_pause = false
			return
			
		if Input.is_action_just_pressed("pda") and pda_enabled:
			pause = true
			Gui.MapWindow.Open()
			Gui.MapWindow.is_open_from_pause = false
			return
			
		if Input.is_action_just_pressed("stats"):
			pause = true
			Gui.SkillWindow.Open()
			Gui.SkillWindow.is_open_from_pause = false
			return
		
		if _key_pressed("scope"):
			if weapon_system.can_scope:
				weapon_system.Scope(true)

					
		if Input.is_action_just_pressed("console"):
			Gui.ConsoleWindow.Open()
			#WipePlayerData()
			#Gui.InventoryWindow.ResetInventorySystem()
			
		if Input.is_action_just_released("scope"):
			if weapon_system.can_scope:
				weapon_system.Scope(false)
			
		
				
		if Input.is_action_just_pressed("wpn1") and weapon_system.pslot:
			if weapon_system.pslot and not weapon_system.is_reloading and player.hud_anim_player.current_animation != "shoot":
				if weapon_system.current_weapon and weapon_system.current_weapon.id != weapon_system.pslot.id:
					weapon_system.last_magazine_wpn[weapon_system.pslot.id] = weapon_system.pslot.ammo_mag
					weapon_system.HideWeapon()
					weapon_system.DrawWeapon("pistol")
			
		if Input.is_action_just_pressed("wpn2") and weapon_system.rslot:
			if weapon_system.current_weapon and weapon_system.current_weapon.id != weapon_system.rslot.id and not weapon_system.is_reloading and player.hud_anim_player.current_animation != "shoot":
				weapon_system.last_magazine_wpn[weapon_system.rslot.id] = weapon_system.rslot.ammo_mag
				weapon_system.HideWeapon()
				weapon_system.DrawWeapon("rifle")
				
func weapon_actions():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not main_menu:
		if player.can_use and not look_at_npc and Input.is_action_pressed("shoot") and weapon_system.current_weapon:
				if weapon_system.current_weapon == weapon_system.rslot and (player.hud_anim_player.current_animation != "wpn_draw" or player.hud_anim_player.current_animation != "wpn_hide"):
					#player.shoot_cam_anim()
					weapon_system.Shoot()
			
		if player.can_use and not look_at_npc and _key_pressed("shoot") and weapon_system.current_weapon:
			if weapon_system.can_shoot and player.hud_anim_player.current_animation != "shoot" and (player.hud_anim_player.current_animation != "wpn_draw" or player.hud_anim_player.current_animation != "wpn_hide"):
				if weapon_system.current_weapon.id == weapon_system.pslot.id:
					#player.shoot_cam_anim()
					weapon_system.Shoot()
			
		if _key_pressed("reload"):
			call_reload()
				
#endregion
# call reload function for weapon
func call_reload():
	if weapon_system.current_weapon and player.hud_anim_player.current_animation != "shoot":
		if weapon_system.current_weapon.ammo_mag < weapon_system.current_weapon.data["clip_ammo_max"]:
			if weapon_system.ammo_in_inv != 0 or weapon_system.infinite_ammo:
				weapon_system.can_shoot = false
				weapon_system.is_reloading = true
				player.PlayHudAnimation(weapon_system.current_weapon.data["reload_anim"])

func _physics_process(_delta):
	if is_game_ready and not GameManager.player.is_dead:
		weapon_actions()

#region Gameplay Functions (Quests adding, Loading levels etc...)
func GetNPCOnLevel(npc_id : String) -> NPC:
	if current_level:
		for npc in current_level.get_children():
			if npc is NPC and npc.id == npc_id:
				return npc as NPC
	
	return null
	
# Event keys control functions		
func HasEventKey(key : String):
	return true if key in event_keys else false

func DontHasEventKey(key : String):
	return true if key not in event_keys else false
	
func AddEventKey(key : String):
	if key not in event_keys:
		event_keys.append(key)
		emit_signal("on_event_key_add",key)

func AddEventKeySilently(key : String):
	if key not in event_keys:
		event_keys.append(key)
	
func DeleteEventKey(key : String):
	event_keys.erase(key)
	
func AddQuest(id:String,title:String,money : int=0,items=[], spot=""):
	quests[id] = {
		"title": title,
		"money": money,
		"reward": items,
		"map_spot_id": spot
	}
	if spot != null and quests_json.has[spot]:
		Gui.MapWindow.AddMarker(spot)
	emit_signal("on_quest_add",quests[id])
	
func AddQuestJson(id:String,silent=false):
	var quest = {
		"id": "",
		"title": "",
		"money": 0,
		"reward": [],
		"map_spot_id": null
	}
	for q in quests_json:
		if q["id"] == id:
			quest["id"] = id
			quest["title"] = Lang.translate(q["title"])
			quest["money"] = q["money"]
			quest["reward"] = q["reward"]
			quest["map_spot_id"] = q["map_spot_id"]
			quests[id] = quest
			break
	if not silent:
		emit_signal("on_quest_add",quests[id])

func CompleteQuest(id:String):
	if quests.has(id):
		if quests[id]["money"] > 0:
			player.AddMoney(quests[id]["money"])
		if len(quests[id]["reward"]) > 0:
			for itm in quests[id]["reward"]:
				Gui.InventoryWindow.AddItem(itm)
				
		quests.erase(id)
		emit_signal("on_quest_complete",id)

func DeleteQuest(id:String):
	if quests.has(id):
		quests.erase(id)

func HasQuest(id:String):
	if quests.has(id):
		return true
	else:
		return false

# Change game level
func change_level(id, silent=false):
	Gui.loading_screen.show()
	loading_autoclose = true
	if current_level != null:
		current_level.queue_free()
		current_level = null
	load_level(id,silent)
	
## Loads game level from packed scene from assets/levels/ folder
## Levels can be created inside project!
func load_level_from_file(id, silent=false):
	start_loading_from_file = true
	if FileAccess.file_exists(app_dir+"assets/levels/%s.tscn" % id):
		_level_loaded = false
		var level_packed : PackedScene = load(app_dir+"assets/levels/%s.tscn" % id) as PackedScene
		var level = level_packed.instantiate()
		Gui.loading_screen.show()
		
		if not level.get_node("level_settings"):
			BugTrap.Crash("Packed level doesn't contain \"level_settings\" node inside!\nPlease add this node with project editor and try again!")
			return
		
		loading_autoclose = true
		if current_level != null:
			current_level.queue_free()
			current_level = null
		World.add_child(level)
		
		for obj in level.get_children():
			if "keys" in obj and obj.keys.keys().has("id"):
				match obj.keys["id"]:
					"spawn_point":
						player.ChangePosition(obj.position)
						player.ChangeRotation(obj.rotation_degrees)
						obj.queue_free()
						continue
					"editor":
						obj.hide()
					"skybox":
						var sky_mat = preload("res://ingame_materials/pito_3d_mat_sky.tres")
						var orig_mat = obj.material_override.duplicate()
						obj.material_override = sky_mat
						obj.material_override.set_shader_parameter("texture_albedo",orig_mat.albedo_texture)
						obj.material_override.set_shader_parameter("direction",sky_speed)
						if not moving_sky_shader:
							obj.material_override.set_shader_parameter("enabled",false)
						else:
							obj.material_override.set_shader_parameter("enabled",true)
					"block":
						_visibility_collision_generation(obj)
					"loot_money":
						_visibility_collision_generation(obj)
					"loot":
						_visibility_collision_generation(obj)
					"usable_area":
						_visibility_collision_generation(obj)
					"transition":
						_visibility_collision_generation(obj)
					"transition_to_level":
						_visibility_collision_generation(obj)
			else:
					
				match obj.name:
					# if we found settings node
					"level_settings":
						# change color of outsky
						print("found level_settings")
						if "weather_color" in obj.keys:
							outsky_color.get_material().albedo_color = obj.keys["weather_color"]
						else:
							BugTrap.Crash("%s->\"level_setting\"->keys <Dict> doesn't contain \"weather_color\" key with color data! Create it!" % id)
							return
						# if has daylight key - set light settings
						if "daylight" in obj.keys:
							var old_mat = player.PlayerCamera.get_node("HUD").material_override
							if obj.keys["daylight"]:
								World.get_node("SceneLight").show()
								old_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
								old_mat.normal_enabled = false
								old_mat.metallic_specular = 0
								player.PlayerCamera.get_node("HUD").material_override = old_mat
								for mat_obj in level.get_children():
									if mat_obj is NPC:
										var orig_mat_0 : StandardMaterial3D = mat_obj.npc_model.get_surface_override_material(0)
										var orig_mat_1 : StandardMaterial3D = mat_obj.npc_model.get_surface_override_material(1)
										orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
										orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
										mat_obj.npc_model.set_surface_override_material(0,orig_mat_0)
										mat_obj.npc_model.set_surface_override_material(1,orig_mat_1)
									if mat_obj.is_class("level_object"):
										if mat_obj.material_override:
											mat_obj.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
									
							else:
								World.get_node("SceneLight").hide()
								old_mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
								old_mat.normal_enabled = true
								old_mat.metallic_specular = 0
								player.PlayerCamera.get_node("HUD").material_override = old_mat
								for mat_obj in level.get_children():
									if mat_obj is NPC:
										var orig_mat_0 : StandardMaterial3D = mat_obj.npc_model.get_surface_override_material(0)
										var orig_mat_1 : StandardMaterial3D = mat_obj.npc_model.get_surface_override_material(1)
										orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
										orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
										mat_obj.npc_model.set_surface_override_material(0,orig_mat_0)
										mat_obj.npc_model.set_surface_override_material(1,orig_mat_1)
									if mat_obj.name != "level_settings" and mat_obj is level_object:
										if "material_override" in mat_obj and mat_obj.material_override != null:
											mat_obj.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
						# if has fog key - set fog
						if "fog" in obj.keys:
							if obj.keys["fog"]:
								player.PlayerCamera.environment.volumetric_fog_enabled = true if volumetric_fog else false
								#player.PlayerCamera.environment.fog_enabled = true if volumetric_fog else false
							else:
								player.PlayerCamera.environment.volumetric_fog_enabled = false
								#player.PlayerCamera.environment.fog_enabled = false
						
						# if has eye distance key - set raycast distance
						# if has view distance - set camera's far parameter
						if "eye_distance" in obj.keys and obj.keys["eye_distance"] != null:
							player.raycast.target_position = Vector3(0,obj.keys["eye_distance"],0)
						if "view_distance" in obj.keys:
							player.PlayerCamera.far = obj.keys["view_distance"]
						else:
							player.PlayerCamera.far = 750
		
		current_level = level
		current_level_id = id
		
		for npc in current_level.get_children():
			if npc is NPC:
				if npc.id == "":
					BugTrap.Crash("NPC [%s] on level [%s] has empty ID!" % [npc.name,id])
					return
				if not npc.is_hostile:
					npc.keys = {
						"id": "npc",
						"profile": npc.id
					}
					npc.profile = npc_json[npc.id]
					npc.PlayAnim("idle")
				else:
					npc.keys = {
						"id": "npc_hostile",
						"profile": npc.id,
						"animations": npc.attack_animations,
						"start_animation": npc.start_animation,
						"zone_id": npc.eyezone_id
					}
					npc.profile = npc_enemy_json[npc.id]
				
		emit_signal("npc_loaded")
		
		#for npc in current_level.get_children():
			#if npc is NPC:
				#npc._ready()
		
		if not silent:
			emit_signal("on_level_changed",id)	
		_level_loaded = true
		start_loading_from_file = false
#endregion

func _visibility_collision_generation(obj):
	if "invisible" in obj.keys and obj.keys["invisible"]:
		obj.transparency = 1
	generate_collider(obj)

## Generate collision for level object
func generate_collider(obj):
	var collider = CollisionShape3D.new()
	var sbody = StaticBody3D.new()
	sbody.name = "static_body"
	sbody.add_child(collider)
	obj.add_child(sbody)
	collider.shape = obj.mesh.create_trimesh_shape()
	collider.name = "collider_trimesh_"+str(collider.get_instance_id())

func on_weapon_shot(dmg,accuracy):
	var skills = GameManager.Gui.SkillWindow as SkillSystem	
	var chance = accuracy + skills.accuracy
	var new_dmg = 0
	#print(chance)	
	var rand = randf_range(0,1)
	if rand <= chance:
		new_dmg = dmg * (100.0 - chance) / 100.0
		#print(chance)
		#GameManager.Gui.ShowMessage("Hit with %.2f damage!" % new_dmg)		
	#else:
		#GameManager.Gui.ShowMessage("Missed! Chance is: %.2f, Random was: %.2f" % [chance, rand])
	#print(new_dmg)
		if player.raycast.is_colliding() and player.raycast.get_collider() and not pause:
			var hit_obj = player.raycast.get_collider().get_parent()
			#print(hit_obj)
			if hit_obj is BONE_COLLISION:
				#print("Shot in %s" % hits_obj.name)
				if hit_obj.npc_obj.is_hostile and not hit_obj.npc_obj.is_dead:
					Gui.crosshair.texture = Gui.crosshair_hit_texture
					hit_obj.npc_obj.Hit(new_dmg)
					hit_obj.npc_obj.hit_blood.position = hit_obj.npc_obj.hit_blood_torso_pos
					
			if hit_obj is BONE_DAMAGE_COLLISION:
				if hit_obj.npc_obj.is_hostile and not hit_obj.npc_obj.is_dead:
					var chance_headshot = 0.8
					if randf_range(0,1) <= chance_headshot:
						Gui.crosshair.texture = Gui.crosshair_headshot_texture
						hit_obj.npc_obj.Hit(999)
						hit_obj.npc_obj.hit_blood.position = Vector3(0.019,1.955,0.516)
						print("Headshot!")
			
			await get_tree().create_timer(0.1).timeout
			Gui.crosshair.texture = Gui.crosshair_gun_texture
			
			if hit_obj != null and hit_obj is level_object and "action" in hit_obj.keys:
				if hit_obj.keys["action"] == "range.spawn.enemy":
					if player.current_eyezone and len(player.current_eyezone.enemies) == 0:
						Gui.ShowMessage("Enemy spawned!")
						create_enemy(["stalker","bandit","soldier","mercenary"].pick_random(),"range_zone",Vector3(-0.50, -1.05, -3.84),Vector3(0,180,0))
					else:
						Gui.ShowMessage("Can't spawn. Kill old enemy!")
					
# -------------- =================================== -------------------

func show_loading():
	Gui.loading_screen.show()
	loading_autoclose = false
	
func hide_loading():
	Gui.loading_screen.hide()
	loading_autoclose = false

#region Level Loading Utilities
# load level utility function that creates collider shape based on json
func _load_level_collider_utility(json,new_obj):
	if "collider" in json:
		var collider = CollisionShape3D.new()
		var sbody = StaticBody3D.new()
		sbody.name = "static_body"
		new_obj.add_child(sbody)
		if json["collider"] == "mesh":
			collider.shape = new_obj.mesh.create_trimesh_shape()
			collider.name = "collider_trimesh_"+str(collider.get_instance_id())
			
		elif json["collider"] == "box":
			collider.shape = BoxShape3D.new()
			collider.shape.size = Vector3(1,1,1)
			collider.name = "collider_box_"+str(collider.get_instance_id())
		else:
			return
			
		sbody.add_child(collider)

# makes object invisible or not when level loading
func _make_obj_invisible(json,obj):
	if "invisible" in json and json["invisible"]:
		# COMPATIBILITY
		obj.material_override = _mat_invisible
		
		# FORWARD+
		#obj.transparency = 1

func create_enemy(profile,eyezone_id,pos,rot,start_animation="shoot_stand_start",animations=["shoot_stand_idle","shoot_stand_left","shoot_stand_right"]):
	var enemy : NPC = preload("res://engine_objects/npc.tscn").instantiate()
	enemy.name = "runtime_enemy_"+str(enemy.get_instance_id())
	enemy.position = pos
	enemy.rotation_degrees = rot
	enemy.scale = Vector3(0.8,0.8,0.8)
	enemy.keys = {"zone_id": eyezone_id}
	enemy.keys["start_animation"] = start_animation
	enemy.keys["animations"] = animations
	enemy.attack_animations = animations
	enemy.profile = npc_enemy_json[profile]
	enemy.id = profile
	enemy.is_hostile = true
	
	current_level.add_child(enemy)
	editor_level_objects.append(enemy)
	return enemy

func create_eyezone(id : String, pos : Vector3, rot : Vector3, size : Vector3):
	var eyezone : EYEZONE = preload("res://engine_objects/hostile_eyezone.tscn").instantiate()
	eyezone.name = "eyezone_"+str(eyezone.get_instance_id())
	eyezone.get_child(0).shape.size = size
	eyezone.position = pos
	eyezone.rotation_degrees = rot
	eyezone.id = id
	current_level.add_child(eyezone)
#endregion

#region Level Loading
# create ID object type when level is loading
func _level_loader_add_id_obj(json,id : String,lvl_node,editor_obj_list, visible_on_screen : bool = true):
	if json["id"] == id:
		var id_obj : MeshInstance3D = MeshInstance3D.new()
		id_obj.name = json["name"] if "name" in json else id+"_"+str(id_obj.get_instance_id())
		if json["model"] == "cube":
			id_obj.mesh = BoxMesh.new()
			id_obj.material_override = StandardMaterial3D.new()
			
		if "texture" in json:
			id_obj.material_override = Utility.set_texture_to_object(Utility.load_external_texture("assets/textures/"+json["texture"]),false,false)
		
		id_obj.position = Vector3(json["position"][0],json["position"][1],json["position"][2])
		id_obj.rotation_degrees = Vector3(json["rotation"][0],json["rotation"][1],json["rotation"][2])
		id_obj.scale = Vector3(json["scale"][0],json["scale"][1],json["scale"][2]) if typeof(json["scale"]) == TYPE_ARRAY else Vector3(json["scale"],json["scale"],json["scale"])
		
		if "collider" in json:
			_load_level_collider_utility(json,id_obj) # create colliders based on type in json
			
		_make_obj_invisible(json,id_obj) # give to our object visibility options
		_level_loader_set_keys_script(json,id_obj) # give our object script that contains all keys from json
		lvl_node.add_child(id_obj)
		if visible_on_screen:
			add_screen_notifier(id_obj)
		editor_obj_list.append(id_obj)
		
# set keys from json to level object
func _level_loader_set_keys_script(json, obj):
	obj.set_script(load("res://scripts/level_object.gd"))
	obj.keys = json		

func on_obj_out_of_screen(notifier : VisibleOnScreenNotifier3D,obj):
	#print(notifier.is_on_screen())
	#print("[%s] is out of screen!" % obj.name)
	#if obj != NPC:
	#	obj.set_physics_process(false)
	#	obj.set_process(false)
	#if obj.has_node("3d_sound"):
	#	obj.get_node("3d_sound").playing = false
		
	if obj is OmniLight3D and obj.global_position.distance_to(GameManager.player.global_position) >= 10:
		obj.distance_fade_enabled = true
		#obj.distance_fade_begin = 0.1
	
func on_obj_in_the_screen(notifier : VisibleOnScreenNotifier3D,obj):
	#print("[%s] is in the screen!" % obj.name)
	#if obj != NPC:
	#	obj.set_physics_process(true)
	#	obj.set_process(true)
	#if obj.has_node("3d_sound"):
	#	obj.get_node("3d_sound").playing = true
		
	if obj is OmniLight3D:
		obj.distance_fade_enabled = false
			
func add_screen_notifier(assign_object):
	var visible_on_screen_3d = VisibleOnScreenNotifier3D.new()
	visible_on_screen_3d.name = "VOSN3D"
	if assign_object is MeshInstance3D:
		visible_on_screen_3d.aabb = assign_object.get_aabb()
	assign_object.add_child(visible_on_screen_3d)
	visible_on_screen_3d.screen_entered.connect(on_obj_in_the_screen.bind(assign_object.get_node("VOSN3D"),assign_object))
	visible_on_screen_3d.screen_exited.connect(on_obj_out_of_screen.bind(assign_object.get_node("VOSN3D"),assign_object))
	
	
# BASE LEVEL LOADER FUNCTION THAT LOAD THE LEVEL
func load_level(id : String,silent=false):
	var level_node = Node3D.new()
	level_node.position = Vector3(0,0,0)
	var level_path = app_dir+"assets/levels/"+id+"/"
	_level_loaded = false
	#if current_level_lights.size() > 0:
	#	for l in current_level_lights:
	#		l.queue_free()
			
	#current_level_lights.clear()
	
	#player.reparent(level_node,false)
	#waypoints.reparent(level_node,true)
	if DirAccess.dir_exists_absolute(level_path):
		var level_data = Utility.read_json("assets/levels/"+id+"/level.json")	
		outsky_color.get_material().albedo_color = Color(level_data["weather_color"])
		
		if "daylight" in level_data:
			var old_mat = player.PlayerCamera.get_node("HUD").material_override
			if level_data["daylight"]:
				World.get_node("SceneLight").show()
				old_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
				old_mat.normal_enabled = false
				old_mat.metallic_specular = 0
				player.PlayerCamera.get_node("HUD").material_override = old_mat
			else:
				World.get_node("SceneLight").hide()
				old_mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
				old_mat.normal_enabled = true
				old_mat.metallic_specular = 0
				player.PlayerCamera.get_node("HUD").material_override = old_mat
		
		
		if "fog" in level_data:
			if level_data["fog"]:
				player.PlayerCamera.environment.volumetric_fog_enabled = true if volumetric_fog else false
				#player.PlayerCamera.environment.fog_enabled = true if volumetric_fog else false
			else:
				player.PlayerCamera.environment.volumetric_fog_enabled = false
				#player.PlayerCamera.environment.fog_enabled = false
				
		if "eye_distance" in level_data and level_data["eye_distance"] != null:
			player.raycast.target_position = Vector3(0,level_data["eye_distance"],0)
		if "view_distance" in level_data:
			player.PlayerCamera.far = level_data["view_distance"]
		else:
			player.PlayerCamera.far = 750
		#if "rotation_range" in level_data:
			#player.rotation_range_y[0] = level_data["rotation_range"][0]
			#player.rotation_range_y[1] = level_data["rotation_range"][1]
		#ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color")
		
		#if waypoints_json:
			#for wp in waypoints_json:
				#if wp["level"] == id:
					#var curve = Curve3D.new()
					#waypoints.curve = curve
					#print("Found waypoints list for [%s] level!" % id)
					#for wp_element in wp["waypoints"].keys():
						#for wp_point in wp["waypoints"][wp_element]["list"].size():
							#var ui_wp_icon = preload("res://engine_objects/ui_waypoint_icon.tscn").instantiate()
							#var pos_x = wp["waypoints"][wp_element]["list"][wp_point]["position"][0]
							#var pos_y = wp["waypoints"][wp_element]["list"][wp_point]["position"][1]
							#var pos_z = wp["waypoints"][wp_element]["list"][wp_point]["position"][2]
							
							#var visibility = VisibleOnScreenNotifier3D.new()
							#curve.add_point(Vector3(pos_x,pos_y,pos_z))
							#ui_wp_icon.instantiate()
							#ui_wp_icon.name = "waypoint_%s" % str(wp_point)
							#Gui.GetUIElement("frame").add_child(ui_wp_icon)
							#ui_wp_icon.position = player.PlayerCamera.unproject_position(Vector3(pos_x,pos_y,pos_z))
							#wp_node.name = "waypoint_%s" % str(wp_point)
							#wp_node.position = Vector3(pos_x,pos_y,pos_z)
							#waypoints_debug.append(ui_wp_icon)
							#waypoints_world.append(wp_node)
							
		
		if "light" in level_data:
			for light in level_data["light"]:
				if light["type"] == "point":
					var color = []			
					color = light["color"]
					var l = Utility.add_point_light(Color(color[0]/255,color[1]/255,color[2]/255,255),light["distance"],light["shadows"],light["energy"],Vector3(light["position"][0],light["position"][1],light["position"][2]),Vector3(light["rotation"][0],light["rotation"][1],light["rotation"][2]))
					l.name = light["name"]
					l.distance_fade_enabled = true
					l.distance_fade_begin = 45
					l.distance_fade_length = 5
					if "flicker" in light and light["flicker"]:
						l.flicker = true
					if "flicker_speed" in light:
						l.flicker_speed = light["flicker_speed"]
					level_node.add_child(l)
					add_screen_notifier(l)
					#current_level_lights.append(l)
					editor_level_objects.append(l)
		for obj in level_data["level_data"]:
			if "uid" in obj and "id" not in obj:
				if obj["uid"] == "skybox":
					pass
					#var sky_model : MeshInstance3D = Utility.load_model(obj["model"]+".obj","assets/textures/"+obj["texture"],Vector3(obj["position"][0],obj["position"][1],obj["position"][2]),Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]),Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"]))
					#sky_model.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					#level_sky = sky_model
					#level_node.add_child(sky_model)
			if "id" in obj:
				if obj["id"] == "sprite3d":
					var sprite_3d = Sprite3D.new()
					sprite_3d.name = obj["name"] if "name" in obj else "game_object_"+str(sprite_3d.get_instance_id())
					sprite_3d.texture = Utility.load_external_texture("assets/textures/"+obj["texture"])
					sprite_3d.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					sprite_3d.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					sprite_3d.rotation = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					sprite_3d.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					sprite_3d.name = obj["name"] if "name" in obj else "sprite3d"
					if "3d_sound" in obj and obj["3d_sound"].keys().size() > 0:
						var new_3d_sound = AudioStreamPlayer3D.new()
						var audio_loader = AudioLoader.new()
						new_3d_sound.ready.connect(new_3d_sound.play)
						new_3d_sound.volume_db = obj["3d_sound"]["volume_db"]
						new_3d_sound.set_stream(audio_loader.loadfile(GameManager.app_dir+obj["3d_sound"]["audio"],true))
						new_3d_sound.max_distance = obj["3d_sound"]["max_distance"]
						sprite_3d.add_child(new_3d_sound)
						print("3d sound created!")
						new_3d_sound.playing = true
					level_node.add_child(sprite_3d)
					add_screen_notifier(sprite_3d)
					editor_level_objects.append(sprite_3d)
					
					
				if obj["id"] == "spawn_point":
					player.ChangePosition(Vector3(obj["position"][0],obj["position"][1],obj["position"][2]))
					player.ChangeRotation(Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]))
					
					
				if obj["id"] == "animated3dsprite":
					var anim3dsprite : AnimatedSprite3D = preload("res://engine_objects/animated_sprite.tscn").instantiate()
					anim3dsprite.name = obj["name"] if "name" in obj else "game_object_"+str(anim3dsprite.get_instance_id())
					anim3dsprite.animation = obj["sequence"] if "sequence" in obj else "Default"
					anim3dsprite.play(obj["sequence"])
					anim3dsprite.pixel_size = 0.04
					anim3dsprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					anim3dsprite.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					anim3dsprite.rotation = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					anim3dsprite.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					if "3d_sound" in obj and obj["3d_sound"].keys().size() > 0:
						var new_3d_sound = AudioStreamPlayer3D.new()
						var audio_loader = AudioLoader.new()
						new_3d_sound.ready.connect(new_3d_sound.play)
						new_3d_sound.name = "3d_sound"
						new_3d_sound.volume_db = obj["3d_sound"]["volume_db"]
						new_3d_sound.set_stream(audio_loader.loadfile(GameManager.app_dir+obj["3d_sound"]["audio"],true))
						new_3d_sound.max_distance = obj["3d_sound"]["max_distance"]
						anim3dsprite.add_child(new_3d_sound)
					add_screen_notifier(anim3dsprite)
					level_node.add_child(anim3dsprite)
					editor_level_objects.append(anim3dsprite)
				
				if obj["id"] == "radiation":
					var rad_trigger = preload("res://engine_objects/rad_trigger.tscn").instantiate()
					rad_trigger.name = obj["name"] if "name" in obj else "rad_trigger_"+str(rad_trigger.get_instance_id())
					rad_trigger.get_child(0).shape.size = Vector3(obj["size"][0],obj["size"][1],obj["size"][2])
					rad_trigger.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					rad_trigger.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					if "scale" in obj:
						rad_trigger.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					level_node.add_child(rad_trigger)
					add_screen_notifier(rad_trigger)
					editor_level_objects.append(rad_trigger)
				
				if obj["id"] == "hostile_eyezone":
					var eyezone = preload("res://engine_objects/hostile_eyezone.tscn").instantiate()
					eyezone.name = obj["name"] if "name" in obj else "eyezone_"+str(eyezone.get_instance_id())
					eyezone.get_child(0).shape.size = Vector3(obj["size"][0],obj["size"][1],obj["size"][2])
					eyezone.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					eyezone.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					eyezone.id = obj["hostile_id"]
					if "scale" in obj:
						eyezone.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					add_screen_notifier(eyezone)
					level_node.add_child(eyezone)
					editor_level_objects.append(eyezone)
					
				if obj["id"] == "godot_prefab":
					var prefab = null
					if "prefab" in obj:
						match obj["prefab"]:
							"underground_doorhole":
								prefab = preload("res://engine_objects/underground_doorhole.tscn").instantiate()
								
						if prefab != null:
							prefab.name = "prefab_"+str(prefab.get_instance_id())
							prefab.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
							prefab.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
							level_node.add_child(prefab)
							add_screen_notifier(prefab)
							editor_level_objects.append(prefab)
							
							
				if obj["id"] == "npc":
					var lvl_npc : NPC = preload("res://engine_objects/npc.tscn").instantiate()
					await get_tree().process_frame
					lvl_npc.name = obj["name"] if "name" in obj else "npc_"+str(lvl_npc.get_instance_id())
					lvl_npc.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					lvl_npc.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					if "scale" in obj:
						lvl_npc.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					else:
						lvl_npc.scale = Vector3(0.8,0.8,0.8)
					lvl_npc.keys = obj
					lvl_npc.profile = npc_json[obj["profile"]]
					lvl_npc.id = obj["profile"]
					lvl_npc.PlayAnim("idle")
					if "lit" in obj and obj["lit"]:
						var orig_mat_0 : StandardMaterial3D = lvl_npc.npc_model.get_surface_override_material(0)
						var orig_mat_1 : StandardMaterial3D = lvl_npc.npc_model.get_surface_override_material(1)
						orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
						orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
						lvl_npc.npc_model.set_surface_override_material(0,orig_mat_0)
						lvl_npc.npc_model.set_surface_override_material(1,orig_mat_1)
					
					level_node.add_child(lvl_npc)
					add_screen_notifier(lvl_npc)
					editor_level_objects.append(lvl_npc)
					
				if obj["id"] == "npc_hostile":
					var lvl_enemy : NPC = preload("res://engine_objects/npc.tscn").instantiate()
					lvl_enemy.name = obj["name"] if "name" in obj else "npc_"+str(lvl_enemy.get_instance_id())
					lvl_enemy.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					lvl_enemy.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					if "scale" in obj:
						lvl_enemy.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					else:
						lvl_enemy.scale = Vector3(0.8,0.8,0.8)
					lvl_enemy.keys = obj
					lvl_enemy.profile = npc_enemy_json[obj["profile"]]
					lvl_enemy.id = obj["profile"]
					lvl_enemy.is_hostile = true
					#lvl_enemy.PlayAnim("idle")
					if "animations" in lvl_enemy.keys and lvl_enemy.keys["animations"]:
						lvl_enemy.attack_animations = lvl_enemy.keys["animations"]
					else:
						lvl_enemy.attack_animations.append("shoot_stand_idle")
						
					if "start_animation" in lvl_enemy.keys:
						lvl_enemy.start_animation = lvl_enemy.keys["start_animation"]
						
					if "lit" in obj and obj["lit"]:
						var orig_mat_0 : StandardMaterial3D = lvl_enemy.npc_model.get_surface_override_material(0)
						var orig_mat_1 : StandardMaterial3D = lvl_enemy.npc_model.get_surface_override_material(1)
						orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
						orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
						lvl_enemy.npc_model.set_surface_override_material(0,orig_mat_0)
						lvl_enemy.npc_model.set_surface_override_material(1,orig_mat_1)
					
					level_node.add_child(lvl_enemy)
					add_screen_notifier(lvl_enemy)
					editor_level_objects.append(lvl_enemy)
					
					
				_level_loader_add_id_obj(obj,"loot_money",level_node,editor_level_objects)
				_level_loader_add_id_obj(obj,"loot",level_node,editor_level_objects)
				_level_loader_add_id_obj(obj,"usable_area",level_node,editor_level_objects)
				_level_loader_add_id_obj(obj,"transition_to_level",level_node,editor_level_objects)
				_level_loader_add_id_obj(obj,"transition",level_node,editor_level_objects)
				_level_loader_add_id_obj(obj,"block",level_node,editor_level_objects)
						
			if "id" not in obj:
				var new_obj = Utility.load_model(obj["model"]+".obj","assets/textures/"+obj["texture"],Vector3(obj["position"][0],obj["position"][1],obj["position"][2]),Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]),Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"]),false,true if "double_sided" in obj and obj["double_sided"] else false)
				new_obj.name = obj["name"] if "name" in obj else "game_object_"+str(new_obj.get_instance_id())
				new_obj.set_script(level_object)
				_load_level_collider_utility(obj,new_obj)
				new_obj.keys = obj
				new_obj.material_override.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				
				
				if "alpha" in obj and obj["alpha"]:
					if OS.has_feature('gles2'):
						new_obj.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					else:
						new_obj.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
						
				else:
					new_obj.material_override.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					
				if "double_sided" in obj and obj["double_sided"]:
					new_obj.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
					
				if "lit" in obj and obj["lit"]:
					new_obj.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				
				if obj["model"] == "assets/models/rad":
					new_obj.material_override = _base_mat_emission.duplicate()
					new_obj.material_override.proximity_fade_enabled = true
					new_obj.material_override.proximity_fade_distance = 1.1
				
				if "billboard" in obj and obj["billboard"]:
					new_obj.material_override.billboard_keep_scale = true
					new_obj.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
				
				#new_obj.visibility_range_end = 25
				
				if obj["texture"].contains("texsky"):
					var sky_mat = preload("res://ingame_materials/pito_3d_mat_sky.tres")
					new_obj.material_override = sky_mat
					new_obj.material_override.set_shader_parameter("texture_albedo",Utility.load_external_texture("assets/textures/"+obj["texture"]))
					new_obj.material_override.set_shader_parameter("direction",sky_speed)
					if not moving_sky_shader:
						new_obj.material_override.set_shader_parameter("enabled",false)
					else:
						new_obj.material_override.set_shader_parameter("enabled",true)
				add_screen_notifier(new_obj)
				level_node.add_child(new_obj)
				editor_level_objects.append(new_obj)
	current_level_id = id
	
	level_node.name = id
	current_level = level_node
	World.add_child(level_node)
	if not silent:
		emit_signal("on_level_changed",id)	
	_level_loaded = true
	if editor_mode:
		var label_3d = preload("res://engine_objects/3d_label.tscn")
		for obj in editor_level_objects:
			var pos_text:Label3D = label_3d.instantiate()
			var name_text:Label3D = label_3d.instantiate()
			name_text.name = "name_3d"
			pos_text.name = "label_3d"
			name_text.render_priority = 1
			pos_text.render_priority = 1
			obj.add_child(pos_text)
			obj.add_child(name_text)
			name_text.position.y = -0.5
			name_text.text = "[%s]" % obj.name
			pos_text.text = "["+str(obj.position) + "]\n"+str(obj.rotation)
		
		Gui.show_editor_object_list(editor_level_objects)

#endregion
