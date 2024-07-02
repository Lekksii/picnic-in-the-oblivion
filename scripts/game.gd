extends Node

class_name Game

## ===================================================
##  Main gameplay script with scenario scripts
##  Created by Leksii 07/October/2023
## ===================================================

@onready var GM = GameManager
@onready var player = get_node("/root/Game/sv/EffectDither/World/Player") as Player
@onready var gui = GM.Gui as GUI
@onready var world = GM.World
@onready var weapon_system = GM.weapon_system as WeaponSystem
@onready var inventory = GM.Gui.InventoryWindow as Inventory
@onready var journal = GM.Gui.JournalWindow as Journal
@onready var pda : Map = GM.Gui.MapWindow as Map
@onready var dialogue : DialogueSystem = GM.Gui.DialogueWindow as DialogueSystem

var npc_killed : int = 0
var show_tutorial : bool = true
var break_cutscene : bool = false

######## CUTSCENES ##########
var cutscene_camera_movement : bool = false
var cutscene_camera_rotation : bool = false
var cutscene_camera_a : Vector3 = Vector3()
var cutscene_camera_b : Vector3 = Vector3()
var cutscene_camera_rot_a : Vector3 = Vector3()
var cutscene_camera_rot_b : Vector3 = Vector3()
var cutscene_slide_speed : float = 0.0
var cutscene_slide_multiplier : float = 1.0

signal cutscene_cam_slided
signal cutscene_cam_rotated
#############################

# # # # # # # # # # # # # #
# Description: Basic gameplay logic script for story of the game
# # # # # # API # # # # # #
# GameManager -> Main gameplay core for every gameplay feature
# GUI -> Script for game screen information elements
# Player -> is main character script for control player's data (health, radiation etc)
# World -> main game world node where locations are spawned
# EventKeys -> string based array that works with dialogue system
# WeaponSystem -> weapon system where you can access current weapon in hand or slots 1 or 2
# Inventory -> main player's items storage window, here you can add or check items that player have
#
# ======================= #
# GAME MANAGER
# ======================= #
# VARIABLES:
#
# var current_level_id : String -> ID of current playable level
# var current_level : Node3D -> object of current playable level
# var look_at_npc : Bool -> shows if player look at NPC
# var event_keys : Array -> array of strings event keys
# var quests : Dictionary -> dictionary for quests
# var in_eyezone : Bool -> shows if player in eyezone or no
# var aim_assist : Bool -> Enable/Disable aim assist
# var ai_ignore : Boold -> enable/disable ai ignoring
# var show_fps : Bool -> show or hide fps
# var developer_mode : Bool -> allows you to handle dev commands by keybard (C - copy pos, V - copy rot)
# 
# var weapon_system : WeaponSystem -> get script with weapon system controls 
#
# JSON DICTIONARIES, they contains all data from configs
#
# var loot_json : Dictionary
# var items_json : Dictionary
# var weapons_json : Dictionary
# var player_json : Dictionary
# var npc_json : Dictionary
# var npc_enemy_json : Dictionary
# var traders_json : Dictionary
# var map_json : Dictionary
# var waypoints_json : Dictionary
#
# METHODS:
#
# ShowPDA(Bool) -> show or hide PDA blink icon on GUI and also turn on/off Map button in pause menu
# ShowMainMenu() -> Shows MM
# HideMainMenu() -> Hides MM
# GetNPCOnLevel(id : String) -> Search for npc on level by id and return NPC type object
# HasEventKey(key : String) -> check if player has event key
# DontHasEventKey(key : String) -> check if player don't has event key
# AddEventKey(key : String) -> Adds event key
# DeleteEventKey(key : String) -> Delete event key from player
# AddQuest(id : String, title : String, money : int=0, items=[]) -> Add your quest with your ID, TITLE, MONEY and Array of items IDs
# CompleteQuest(id : String) -> Complete quest and gives you reward
# LoadGameLevel(id : String) -> load level by ID assets/levels/ID folder
# create_enemy(profile : String, eyezone_id : String, pos : Vector3, rot : Vector3) -> create hostile npc
# PlaySFX(path : String) -> Play audio with full path "assets/sounds/sound.wav"
# ======================= #
# GUI (GAME USER INTERFACE)
# ======================= #
# VARIABLES:
#
# var hint : Label -> text tip under crosshair when interract with objects
#
# METHODS:
#
# LoadHelpTipJson(id : String) -> Loads help tip for tutorials etc.
# 
# ======================= #
# PLAYER
# ======================= #
# VARIABLES:
#
# var DebugFly : bool -> unlock camera position and player can fly on WASD, QE for up/down
# var debug_info : bool - > Shows debug information like position, rotation etc.
# var can_look : bool -> lock/unlock possibility to move camera by mouse
# var can_use : bool -> lock/unlock F button for use
# var health : float -> player's health
# var health_max : float -> player's maximum health
# var armor : float -> armor (not implemented)
# var damage : Array -> Array of minimum and maximum damage [min, max]
# var accuracy : float -> player's accuracy affects on damage
# var anomaly_armor : float -> radiation damage resistance (not implemented)
# var money : int -> player's money
# var antirad : bool -> enable/disable full radiation resistance
# var radiation : bool -> enable/disable radiation hazard damage
# var radiation_timer : float -> delay betwen damage hits by radiation
# var antirad_timer : float -> time how long antiraadiation resistance pills will be affected
# var fov : int -> changes camera fov, have bug with HUD weapon hands when changes it, do not touch
# 
# METHODS:
#
# AddMoney(int) -> + money
# LowMoney(int) -> - money
# SetMoney(int) -> set money value to your value
# ChangePosition(Vector3) -> set player's position
# ChangeRotation(Vector3) -> set player's rotation
# Hit(float) -> hit player
# Heal(float) -> heal player
# SetMaxHp(float) -> set max health to your value
# AddMaxHp(float) -> ADDS amount to your max health
# LowMaxHp(float) -> MINUS amount from your max health
# SetHealth(float) -> set player's health
#
# PlayAudio(sound_player, file) -> sound_player : AudioStreamPlayer can be 
# audio_sfx (only for footsteps) or audio (for shoots or etc.) they just two separately 
# created sound sources, and file : String like "assets/sounds/file.wav"
#
# # # # # # # # # # # # # # #
# NPC ANIMATIONS
# # # # # # # # # # # # # # # 
# RESET
# death_sit_left
# death_sit_right
# death_stand
# idle
# idle_arm
# idle_cross
# idle_sit_table_1
# idle_warm_hands
# idle_weapon
# shoot_sit_left
# shoot_sit_right
# shoot_sit_start
# shoot_sit_up
# shoot_sit_up_left
# shoot_sit_up_right
# shoot_stand_idle
# shoot_stand_left
# shoot_stand_right
# shoot_stand_start
# sit_ground
# sit_on_greenbox
# sit_on_greenbox_2

# callback when game fully loaded and started
func main_game_init():
	print("[game.gd] -> init completed!\n")
	# load script in game from assets folder
	
	
	GM.on_level_changed.connect(on_level_changed)
	GM.on_npc_kill.connect(on_npc_kill)
	GM.on_quest_add.connect(on_quest_add)
	GM.on_quest_complete.connect(on_quest_complete)
	GM.on_npc_talk.connect(on_npc_talk)
	GM.on_event_key_add.connect(on_event_key_add)
	GM.on_door_used.connect(on_door_used)
	GM.on_npc_animation_finished.connect(on_npc_animation_finished)
	GM.on_item_used.connect(on_item_used)
	gui.DialogueWindow.dialogue_started.connect(on_dialogue_start)
	gui.DialogueWindow.dialogue_ended.connect(on_dialogue_end)
	gui.Loot.on_item_took.connect(on_loot_item_took)
	player.in_eyezone.connect(come_in_eyezone)
	player.out_from_eyezone.connect(out_from_eyezone)
	player.dead.connect(on_player_death)
	
	print("[game.gd] -> all signals connected!\n")
	
	await GM.on_game_ready
	GameAPI.RunOutsideScript("p_game")
	
	await get_tree().process_frame
	
	GameAPI.RunOutsideScript("p_game")._ready()
	
# callback every tick when game works
func main_game_update(_delta):
	if GameAPI.RunOutsideScript("p_game") != null:
		GameAPI.RunOutsideScript("p_game")._process(_delta)
		
	if cutscene_camera_movement:
		if not GM.player.global_position.distance_to(cutscene_camera_b) < 0.1:
			GM.player.global_position = GM.player.global_position.move_toward(cutscene_camera_b,_delta/cutscene_slide_speed * cutscene_slide_multiplier)
			if break_cutscene:
				GM.player.global_position = cutscene_camera_b
				cutscene_cam_slided.emit()
				cutscene_camera_movement = false
				cutscene_camera_a = Vector3.ZERO
				cutscene_camera_b = Vector3.ZERO
				break_cutscene = false
		else:
			cutscene_cam_slided.emit()
			cutscene_camera_movement = false
			cutscene_camera_a = Vector3.ZERO
			cutscene_camera_b = Vector3.ZERO
			
	if cutscene_camera_rotation:
		GM.player.PlayerCamera.rotation.x = lerp_angle(GM.player.PlayerCamera.rotation.x,cutscene_camera_rot_b.x,_delta/cutscene_slide_speed * cutscene_slide_multiplier)
		GM.player.rotation.y = lerp_angle(GM.player.rotation.y,cutscene_camera_rot_b.y,_delta/cutscene_slide_speed * cutscene_slide_multiplier)
		GM.player.PlayerCamera.rotation.z = lerp_angle(GM.player.PlayerCamera.rotation.z,cutscene_camera_rot_b.z,_delta/cutscene_slide_speed * cutscene_slide_multiplier)
		
	if GM.Gui.final_image.visible and GM.Gui.final_image.modulate.a < 1.0:
		GM.Gui.final_image.modulate.a += _delta / 18
		
func cutscene_rotate_camera(from : Vector3, to : Vector3,speed : float = 4.0, multiplier : float = 1.0):
	GM.player.ChangeRotationCutScene(from)
	cutscene_slide_speed = speed
	cutscene_slide_multiplier = multiplier
	cutscene_camera_rot_a = from
	cutscene_camera_rot_b = to
	cutscene_camera_rotation = true

func cutscene_slide_camera(from : Vector3, to : Vector3,speed : float = 4.0, multiplier : float = 1.0):
	GM.player.ChangePosition(from)
	cutscene_slide_speed = speed
	cutscene_slide_multiplier = multiplier
	cutscene_camera_a = from
	cutscene_camera_b = to
	cutscene_camera_movement = true

# additional function for showing tutorial tips if that option enabled
func _show_tutorial(id : String):
	if show_tutorial:
		gui.LoadHelpTipJson(id)		

func on_player_death():
	if GameAPI.RunOutsideScript("p_game") and GameAPI.RunOutsideScript("p_game").has_method("on_player_death"):
		GameAPI.RunOutsideScript("p_game").on_player_death()

func on_npc_talk(npc : NPC):
	if GameAPI.RunOutsideScript("p_game") and GameAPI.RunOutsideScript("p_game").has_method("on_npc_talk"):
		GameAPI.RunOutsideScript("p_game").on_npc_talk(npc)
		
	print("[on_npc_talk]: player talk to %s" % npc.profile["name"])

func on_item_used(itm : item):
	if GameAPI.RunOutsideScript("p_game") and GameAPI.RunOutsideScript("p_game").has_method("on_item_used"):
		GameAPI.RunOutsideScript("p_game").on_item_used(itm)
		
	print("[on_item_used]: %s was used." % itm.ID)

# additional function for checking how many npc's was killed
func _check_kills_on_level(lvl: String, killed: int, eyezone_id : String, eyezone):
	if GM.current_level_id == lvl:
		if npc_killed == killed and eyezone_id == eyezone.id:
			npc_killed = 0
			return true
		else:
			return false

# Calls when player kill an hostile npc
# Main counts for some logic write only here
func on_npc_kill(eyezone,_npc_id,_loot):
	npc_killed += 1
	
	GameAPI.RunOutsideScript("p_game").on_npc_kill(eyezone,_npc_id,_loot)
		
# Calls every time when player change locations, level_id:String argument of new level id
func on_level_changed(level_id):
	GM.ambient_system.player_on_level.emit(level_id)
	GameAPI.RunOutsideScript("p_game").on_level_changed(level_id)
	pda.SetPlayerSpotbyLevelId(level_id)
	#print("Level changed to [%s]" % level_id)
	

# Call when any quest is added, argument - Dict{} of quest data
func on_quest_add(quest):
	#print("[QUEST]: Was added new quest [%s]" % str(quest))
	GameAPI.RunOutsideScript("p_game").on_quest_add(quest)
	
			
# Call when any quest is completed, argument - Dict{} of quest data
func on_quest_complete(quest):
	GameAPI.RunOutsideScript("p_game").on_quest_complete(quest)
	
	
func on_event_key_add(key):
	# Test
	match key:
		"dev.test.red": 
			pda.AddMarker("village_marker")
			GM.AddEventKey("rusty.first.dialogue.done")
			GM.AddEventKey("rusty.second.dialogue.start")
			inventory.AddItem("medkit")
			
		"dev.test.garbage":
			pda.AddMarker("garbage_camp_marker")
			
		"dev.mode":
			player.DebugFly = true
			GM.developer_mode = true
			
		"dev.mode.ai.ignore":
			GM.ai_ignore = true
			
		"dev.complete.game":
			pda.AddMarker("garbage_camp_marker")
			pda.AddMarker("find_camp_spot")
			GM.AddEventKey("radio.start.quest")
			GM.AddEventKey("coward.talk.done")
			#GM.AddEventKey("batka.first.dialogue")
			#GM.AddEventKey("batka.second.dialogue")
			#GM.AddEventKey("batka.battery.quest")
			#GM.AddEventKey("loot.batka.art.found")
			#GM.AddEventKey("batka.talk.done")
			#GM.AddEventKey("batka.info.about.cap")
			#GM.AddEventKey("cap.dialogue.done")
			#GM.AddEventKey("manikovsky.alive")
			#GM.AddEventKey("kaizanovsky.no.dialogue")
			#GM.AddEventKey("kaizanovsky.second.group.quest")
			#GM.AddEventKeySilently("cobold.first.dlg.done")
			#GM.AddEventKey("batka.talk.done")
			#GM.AddEventKey("scientists.in.zone")
			GM.ShowPDA(false)
			
		# Test
		"dev.test.whistle":
			GM.AddEventKey("rusty.quest.whistle.not.complete")
			#GM.AddQuestJson("quest_rusty_1")
	
	GameAPI.RunOutsideScript("p_game").on_event_key_add(key)
	#print("[EVENT KEY]: Was added new key -> %s" % key)

# Call when any dialogue start, argument - ID of opened dialogue
func on_dialogue_start(id):
	GameAPI.RunOutsideScript("p_game").on_dialogue_start(id)
	#print("[DIALOGUE]: Start %s dialogue" % id)
	pass

# Call when any dialogue ends, argument - ID of closed dialogue
func on_dialogue_end(id):
	GameAPI.RunOutsideScript("p_game").on_dialogue_end(id)
	#print("[DIALOGUE]: Dialogue %s ended" % id)
	pass
	
# Call when any item from lootbox was took, argument - ID of item
func on_loot_item_took(id):
	#print("[LOOTBOX]: Item %s taken" % id)
	#print("It was on level [%s]" % lvl)
	GameAPI.RunOutsideScript("p_game").on_loot_item_took(id)
	
	
func _get_transition_trigger(_name:String):
	return GM.current_level.get_node(_name)

# Call when any door was used (transition, transition_to_level), argument - Dict{} of level object data
func on_door_used(door_data):
	GameAPI.RunOutsideScript("p_game").on_door_used(door_data)
	
		
# Call when player came to eyezone	
func come_in_eyezone(eyezone):
	npc_killed = 0
	GameAPI.RunOutsideScript("p_game").come_in_eyezone(eyezone)

# Call when player out from eyezone
func out_from_eyezone(eyezone):
	#print("Out from eyezone, clear kills")
	npc_killed = 0	
	GameAPI.RunOutsideScript("p_game").out_from_eyezone(eyezone)
	
# Call when NPC played animation and it was finished
func on_npc_animation_finished(npc : NPC, anim_name : String):
	GameAPI.RunOutsideScript("p_game").on_npc_animation_finished(npc, anim_name)
	
# Call when Player came in ANY area 3D
func on_area3d_entered(area, who):
	print("%s entered in %s area" % [who.name,area.name])

# Call when Player comes out ANY area 3D
func on_area3d_exited(area, who):
	print("%s exited from %s area" % [who.name,area.name])

func _process(_delta):
	if has_node("/root/Game/CanvasLayer/GUI/BugTrap"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	#if player.is_cutscene:
		#if Input.is_action_just_pressed("take_all"):
			#player.is_cutscene = false
			#player.can_use = true
			#player.can_look = true
			#GM.Gui.SetWeaponHUD(true)
			#GM.Gui.SetHUD(true)
		
	#DisplayServer.window_set_title("Resolution: %s" % str(DisplayServer.window_get_size()))
