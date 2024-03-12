# ALWAYS extend script from Node, else game will crash, cause script handler error.
extends Node

# # # # # # # # # # # # # #
# Description: Basic gameplay logic script for story of the game.
# ALSO, code here and for the game must be written in GDScript, GodotEngine4 scripting language.
# This language closely looks like Python programming language, so game modding must be easy. :)
# # # # # # # # # # # # # #

# # # # # # API # # # # # #
# GameManager -> Main gameplay core for every gameplay feature
# GUI -> Script for game screen information elements
# Player -> is main character script for control player's data (health, radiation etc)
# World -> main game world node where locations are spawned
# EventKeys -> string based array that works with dialogue system
# WeaponSystem -> weapon system where you can access current weapon in hand or slots 1 or 2
# Inventory -> main player's items storage window, here you can add or check items that player have
# GameAPI -> script handler that load outside game script files
# Lang -> Translates key:pair json structure for languages, search for keys in assets/texts/lang_*.json files and return it's value, based on current language code in assets/options.json
# MainMenu -> main menu script
# AmbientSystem -> allows us to play background music and sounds on levels
# SkillSystem -> system that controls player's skills
# UI -> singleton script that allow you to create custom GUI elements
# ======================= #
# MAIN MENU
# ======================= #
# VARIABLES:
#
# var version_title : Label -> Text of game version in left bottom corner
# var selected_button : Label -> Central big button in menu
# var left_button : Label -> Left small gray button
# var right_button : Label -> Right small gray button
#
# ======================= #
# GAME API
# ======================= #
# METHODS:
#
# RunOutsideScript(script_name : String) -> load and handle inside game script from outside of the game in scripts folder
#
# ======================= #
# AMBIENT SYSTEM
# ======================= #
# METHODS:
#
# MainMenuAmbientOff() -> stops all ambient sounds
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
# change_level(id : String) -> load level by ID assets/levels/ID folder
# create_enemy(profile : String, eyezone_id : String, pos : Vector3, rot : Vector3) -> create hostile npc
# PlaySFX(path : String) -> Play audio with name without type, put sound in "assets/sounds/*.wav"
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
#
# ======================= #
# UI (GAME CUSTOM USER INTERFACE for MODDING)
# ======================= #
#
# METHODS:
# CreateLabel(text:String, pos:Vector2, size:Vector2, color:Color ,font:String ,anchor:String) -> Create Label (text - label text, color - Color("#000000") or Color(255,255,255), font - "regular" or "bold", anchor - "anchor_preset" see presets at bottom of file)
# CreateImage(path : String, pos:Vector2, size:Vector2, color:Color ,anchor:String) -> Create Image (path - full asset path, like example "assets/ui/image.png")
# CreateButton(text : String, press_function, pos:Vector2, size:Vector2, color:Color ,anchor:String) -> Create Button (text - button text, press_function - put here name of your function, also it can handle lambda function)
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
# ======================= #
# LANG
# ======================= #
# METHODS:
#
# translate(keys : String) -> search for key in *_lang.json file to return it's value, if no key found, returns key itself
# translate_string(text : String) -> translate text using *_lang.json file of current language.
#
# ======================= #
# SKILL SYSTEM
# ======================= #
# METHODS:
#
# AddExp(amount : int) -> adds some amount of expirience points
# AddSkillPoint(amount : int) -> adds some amount of skill points
# UpgradeSkill(skill : string) -> upgrade skill: armor, accuracy, resistance, health, strenght
# _ResetSkills() -> reset skills to basic numbers that player has when starting new game
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
# shoot_stand_idle_cutscene
# weapon_stand_idle_story
# story_manikovsky_safe
# story_manikovsky_battle
# sit_ground_death

# ########## # [WARNING] # ########## #
# scripts can run only _ready() and _process(delta) functions!
#
# [TIP]
# If you want to access to another script, firstly make sure that you've created it,
# then add to _ready() function that code. Make sure to register it firstly:
#
# GameAPI.RunOutsideScript("your_script_name")
#
# And then script will be registered and handled in game and you can acces to it
# in any place using same code. Also you have access to your own functions inside
# that script. Example:
# ------------------------------- EXAMPLE -----------------------------
# Script "test.gd" in assets/scripts/
#
# func foo(a,b):
# 	var result = a + b
#	return result
#
# Then inside game in func _ready() you can register your script and use your function:
#
# [VARIANT 1]:
#
# func _ready():
#	var test = GameAPI.RunOutsideScript("test").foo(1,2)
#	print(test) <--- will return 3 as result
#
# [VARIANT 2]:
#
# func _ready():
#	 GameAPI.RunOutsideScript("test")
#	 	var test = GameAPI.RunOutsideScript("test").foo(1,2)
#		print(test) <--- will return 3 as result
#
# ########## # [WARNING] # ########## #

## ===================================================
##  Main gameplay script with scenario functions, here you can build any mod logic
##  Created by Leksii 09/01/2024
## ===================================================

# ########## # [VARIABLES] # ########## #
var GM = GameManager
var gui = GM.Gui as GUI
var world = GM.World
var weapon_system = GM.weapon_system as WeaponSystem
var inventory = GM.Gui.InventoryWindow as Inventory
var journal = GM.Gui.JournalWindow as Journal
var pda : Map = GM.Gui.MapWindow as Map
var skills : SkillSystem = GM.Gui.SkillWindow as SkillSystem
var dialogue : DialogueSystem = GM.Gui.DialogueWindow as DialogueSystem
var player : Player = GM.GameProcess.player as Player
var game_process : Game = GM.GameProcess as Game

# dictionary with quests exp
var quests_exp_table = {
	"reds_bandits": 5,
	"reds_whistler": 8,
	"galosh_art": 6,
	"coward": 11,
	"harya": 5,
	"batya_battery": 15,
	"manikovsky": 25,
	"belomor": 13,
	"cd_disk": 33,
	"zob_merc": 65
}
# ########## # [VARIABLES] # ########## #

# Called when gameplay init completed and game starts play
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# ------------------------
# Gameplay callbacks
# ------------------------

# Calls when player kill an hostile npc
# [ARGUMENTS]: 
# eyezone <- returns battle eyezone with list of enemies
# _npc_id <- returns string with npc ID
# _loot <- returns array with items ID
#
# [TIP]:
#
# For checking how much enemies was killed, you can use _check_kills_on_level() from GameProcess
# game_process._check_kills_on_level("level_id" : string,amount : int, "eyezone_id" : string, eyezone <- don't touch this arg, keep it here always)
#
# [EXAMPLE]:
# 
# if game_process._check_kills_on_level("test_level",5,"enemy_eyezone1",eyezone):
#		print("Congrats, you kill 5 enemies on level test_level, now you can do something, maybe add quest)
#		GM.AddQuestJson("quest_id")

func on_npc_kill(eyezone,_npc_id,_loot):
	# INTRO BATTLE
	if game_process._check_kills_on_level("intro_battle",2, "eyezone_battle_intro",eyezone) and GM.DontHasEventKey("intro.battle.2.kills"):
		#gui.ShowMessage("Killed 2 enemies. PDA marker added!")
		GM.AddEventKey("intro.battle.2.kills")
		
	# FOREST ROAD
	if game_process._check_kills_on_level("forest_road",5,"forest_road_battle",eyezone) and GM.DontHasEventKey("forest.road.5.kills"):
		GM.AddEventKey("forest.road.5.kills")
		
	# WHISTLER COLLECTORS LEVEL
	if game_process._check_kills_on_level("svistun_collectors",2,"eyezone_svistun_4",eyezone):
		print("Door transition_to_tunnel_red4 hided!")
		GM.current_level.get_node("transition_to_tunnel_red4").hide()
		
	if game_process._check_kills_on_level("svistun_collectors",3,"eyezone_svistun_8",eyezone):
		GM.current_level.get_node("transition_to_tunnel_red9").hide()
		GM.AddEventKey("svistun.last.enemies.killed")
		
	if game_process._check_kills_on_level("harya_outfit_road",3,"harya_road_eyezone1",eyezone):
		GM.AddEventKey("harya.bandits.completed")
		
	if game_process._check_kills_on_level("manikovsky",3,"eyezone_manikovsky8",eyezone):
		GM.GetNPCOnLevel("manikovsky_profile").PlayAnim("story_manikovsky_safe")
		
	if game_process._check_kills_on_level("manikovsky",1,"manikovsky_elimination_zone",eyezone):
		await get_tree().create_timer(1.0).timeout
		dialogue.StartDialogue("radio_evac_dialogue","npc.radio")
		
	if game_process._check_kills_on_level("evac_point",5,"evac_eyezone1",eyezone):
		GM.AddEventKey("evacuation.failed")
		
	if game_process._check_kills_on_level("belomor_friends",6,"belomor_eyezone",eyezone):
		GM.AddEventKey("belomor.friends.quest.completed")
	
	# if we killed 2 enemies in shlang underhround - create ambush
	if game_process._check_kills_on_level("shlang_cd_underground",2,"shlang_cd_eyezone4",eyezone):
		GM.AddEventKey("shlang.cd.zasada")
	
	# if we killed 2 enemies at the last eyezone in city - complete quest
	if game_process._check_kills_on_level("city_alley",2,"eyezone_merc_3",eyezone):
		GM.AddEventKey("zob.quest.completed")

# Calls every time when player change locations, [level_id : String] argument of new level id
func on_level_changed(level_id):
	# ARRAY with IDs of safe levels, where player can be saved when open menu or trade in camp
	# PLEASE DO NOT DELETE THIS, CAUSE OF GAMEPLAY ISSUES WITH SAVE/LOAD OUT OF CAMPS
	var safe_levels_ids = ["village","garbage_camp","first_group"]
	
	# clear loot window items when we changed level, maybe it will keep us from bugs
	gui.Loot.Clear()
	
	if safe_levels_ids.has(level_id):
		#print("%s is safe!" % level_id)
		GM.level_is_safe = true
	else:
		GM.level_is_safe = false
			
	match level_id:
		"intro_battle": 
			pda.AddMarker("intro_marker")
			await get_tree().process_frame
			if OS.has_feature("windows"):
				game_process._show_tutorial("first_battle_tip")
			if OS.has_feature("mobile"):
				game_process._show_tutorial("first_battle_tip_mob")
				
		"intro":
			gui.ShowIntroMessageCustom("start.game.info")
			#print("waint until gui intro will be hidden")
			await gui.IntroWindow.hidden
			#GM.AddEventKey("intro.cutscene")
			#print("intro hidden!")
			await get_tree().create_timer(1.5).timeout
			if OS.has_feature("windows"):
				game_process._show_tutorial("interaction_tip")
			if OS.has_feature("mobile"):
				game_process._show_tutorial("interaction_tip_mob")
			
		"village":
			if pda.GetMarker("intro_marker"):
				pda.DeleteMarker("intro_marker")
			GM.SaveGame() # Save Game without any story breaking
		
		"village_e3":
			GM.SaveGame() # Save Game without any story breaking			
		
		"garbage_camp":
			#for marker in GM.map_json.keys():
			#	pda.AddMarker(marker)
			#GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		"first_group":
			GM.SaveGame() # Save Game without any story breaking
			
		"manikovsky":
			GM.GetNPCOnLevel("manikovsky_profile").PlayAnim("story_manikovsky_battle")
			GM.AddEventKey("manikovsky.dialogue.done")
			
		"kaizanovsky_group2_final_underground":
			GM.SaveGame() # Save Game without any story breaking
			
		"kaizanovsky_group2_final":
			GM.AddEventKey("final.cutscene")
	
# Calls when any quest is added, argument - Dict{} of quest data, it looks like object from file assets/gameplay/quests.json
func on_quest_add(quest):
	match quest.id:
		"quest_rusty_0":
			GM.ShowPDA(true)
			pda.AddMarker("forest_road_spot")
			GM.SaveGame() # Save Game without any story breaking
			
		"quest_rusty_1":
			GM.ShowPDA(true)
			pda.AddMarker("find_whistle_spot")
			GM.SaveGame() # Save Game without any story breaking
			
		"quest_talk_radio": # When we get radio from Red - block PDA for non use radio in other locations (it will break the game)
			GM.ShowPDA(false)
			GM.SaveGame() # Save Game without any story breaking
	
# Calls when any quest is completed, argument - Dict{} of quest data
func on_quest_complete(quest):
	match quest:
		# when we done quest by rusty for killing bandits on road
		"quest_rusty_0":
			GM.AddEventKey("rusty.second.dialogue.start")
			
		"quest_rusty_1":
			GM.AddEventKey("rusty.whistle.quest.complete")
	
# Calls when player get Event Key [key : String], main function for gameplay logic as quests, events, some rules etc.
func on_event_key_add(key):
	# event keys match for logic
	match key:
		"intro.battle.2.kills":
			pda.AddMarker("find_camp_spot")
			await get_tree().create_timer(0.5).timeout
			if OS.has_feature("windows"):
				game_process._show_tutorial("pda_tip")
			if OS.has_feature("mobile"):
				game_process._show_tutorial("pda_tip_mob")
				
			GM.ShowPDA(true)
		
		"forest.road.5.kills":
			pda.DeleteMarker("forest_road_spot")
			GM.CompleteQuest("quest_rusty_0")
			gui.SkillWindow.AddExp(quests_exp_table["reds_bandits"])
			GM.ShowPDA(true)
		
		# when added key for quest 1 by galosh
		"galosh.art.quest.added":
			GM.AddQuestJson("quest_galosh")
			pda.AddMarker("find_medusa_spot")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		# when added key for quest 2 by rusty
		"whistler.quest.done":
			GM.DeleteEventKey("rusty.quest.whistle.not.complete")
			pda.DeleteMarker("find_whistle_spot")
			GM.ShowPDA(true)
		
		# if we don't gave medkit to whistler - play death anim
		"whistler.dead":
			GM.GetNPCOnLevel("whistler_profile").can_talk = false # also we cannot talk now
			GM.GetNPCOnLevel("whistler_profile").PlayAnim("sit_ground_death")
			GM.GetNPCOnLevel("whistler_profile").r_hand.hide() # hide weapon from hand
		
		# When we complete first quest of Red
		"rusty.whistle.complete.quest":
			gui.SkillWindow.AddExp(quests_exp_table["reds_whistler"])
			GM.CompleteQuest("quest_rusty_1")
		
		# when we found medusa on galosh art location
		"loot.galosh.art.found":
			pda.DeleteMarker("find_medusa_spot")
			GM.ShowPDA(true)
			gui.SkillWindow.AddExp(quests_exp_table["galosh_art"])
			# Set galosh dialogue to no_dialogue state with "thanks" words
			GM.AddEventKey("galosh.dialogue.done")
			GM.CompleteQuest("quest_galosh")
		
		# When player used radio
		"radio.start.quest":
			GM.CompleteQuest("quest_talk_radio")
			GM.AddQuestJson("quest_find_cap")
			pda.AddMarker("coward_find_cap_marker")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		# When player done talk with coward
		"coward.talk.done":
			GM.CompleteQuest("quest_find_cap")
			pda.DeleteMarker("coward_find_cap_marker")
			gui.SkillWindow.AddExp(quests_exp_table["coward"])
			pda.AddMarker("garbage_camp_marker")
			GM.ShowPDA(true)
			
		# Here we get quest from harya for merc outfit
		"harya.gived.quest.bandits":
			#var markers = ["harya_outfit_road","harya_bandits_marker"]
			GM.AddEventKey("harya.first.dialogue") 
			GM.AddQuestJson("harya_bandits_outfit")
			pda.AddMarker("harya_outfit_road")
			GM.AddEventKey("harya.talk.done") # Block to talking until we complete quest
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		"harya.bandits.completed":
			GM.DeleteEventKey("harya.talk.done") # Unlock dialogues for harya
			GM.CompleteQuest("harya_bandits_outfit")
			pda.DeleteMarker("harya_outfit_road")
			gui.SkillWindow.AddExp(quests_exp_table["harya"])
			GM.ShowPDA(true)
		
		"harya.second.dialogue":
			GM.AddEventKey("harya.talk.done") # Block to talking forever
			
		"batka.battery.quest": #when we accept quest from batka
			GM.AddQuestJson("batka_find_battery")
			pda.AddMarker("batka_battery_marker")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
		
		"loot.batka.art.found": # when we found art in quest level
			pda.DeleteMarker("batka_battery_marker")
			GM.CompleteQuest("batka_find_battery")
			gui.SkillWindow.AddExp(quests_exp_table["batya_battery"])
			GM.ShowPDA(true)
			
		"batka.info.about.cap": #info apout cap from batka (underground under agroprom)
			pda.AddMarker("batka_find_cap_marker")
			GM.AddQuestJson("quest_find_cap_agroprom_underground")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
		
		"cap.dialogue.done": #info by cap to eleminate scientist
			GM.CompleteQuest("quest_find_cap_agroprom_underground")
			GM.AddQuestJson("eliminate_manikovsky_quest")
			pda.DeleteMarker("batka_find_cap_marker")
			pda.AddMarker("kill_manikovsky")
			GM.ShowPDA(true)
			
		"manikovsky.kill": #Make manikovsky hostile (delete npc and spawn AI at his position)
			GM.CompleteQuest("eliminate_manikovsky_quest")
			if GM.current_level_id == "manikovsky":
				GM.GetNPCOnLevel("manikovsky_profile").queue_free()
				GM.create_eyezone("manikovsky_elimination_zone",player.position,Vector3.ZERO,Vector3(2,2,2))
				await get_tree().create_timer(0.1).timeout
				GM.create_enemy("manikovsky_ai","manikovsky_elimination_zone",Vector3(25.38,0,-93.46),Vector3(0,53.06,0),"shoot_stand_idle",["shoot_stand_idle"])
			pda.DeleteMarker("kill_manikovsky")
			GM.DeleteEventKey("batka.talk.done") # make possibility to talk with batka for new dialogues
		
		"manikovsky.alive": # If we keep manikovsky alive - just take map marker and quest
			pda.DeleteMarker("kill_manikovsky")
			pda.AddMarker("first_group")
			GM.CompleteQuest("eliminate_manikovsky_quest")
			GM.AddQuestJson("find_kaizanovsky")
			gui.SkillWindow.AddExp(quests_exp_table["manikovsky"])
			GM.ShowPDA(true)
		
		"radio.evacuation": # Evacuation by headquarter (no)
			pda.AddMarker("evacuation")
			GM.AddQuestJson("arrive_to_exit")
			GM.ShowPDA(true)
			
		"sos.signal":
			GM.AddQuestJson("sos_signal")
			pda.AddMarker("sos")
			
		"zob.quest":
			GM.AddQuestJson("quest_zob_kill_merc")
			GM.CompleteQuest("sos_signal")
			GM.ShowPDA(true)
			pda.AddMarker("city")
			
		"zob.quest.completed":
			pda.DeleteMarker("city")
			GM.ShowPDA(true)
			GM.CompleteQuest("quest_zob_kill_merc")
			
		"zob.gives.reward":
			inventory.AddItem("ecolog_suit")
			GM.current_level.get_node("garbage_suit").hide()
			player.AddMoney(350,true)
			skills.AddExp(quests_exp_table["zob_merc"], true)
			pda.DeleteMarker("sos")
			
		"evacuation.failed":
			GM.ShowPDA(true)
			GM.CompleteQuest("arrive_to_exit")
			pda.DeleteMarker("evacuation")
			GM.AddQuestJson("quest_ask_about_scientists")
			GM.AddQuestJson("sos_signal")
			pda.AddMarker("sos")
			
		"scientists.in.zone": # same as manikovsky.alive
			pda.AddMarker("first_group")
			GM.AddQuestJson("find_kaizanovsky")
			GM.CompleteQuest("quest_ask_about_scientists")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		"belomor.friends.quest": # start quest of belomor's friends
			pda.AddMarker("belomor_friends")
			GM.AddQuestJson("belomors_friends")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		"belomor.friends.quest.completed": # complete belomor's quest after killing his friends
			GM.CompleteQuest("belomors_friends")
			pda.DeleteMarker("belomor_friends")
			gui.SkillWindow.AddExp(quests_exp_table["belomor"])
			GM.ShowPDA(true)
			
		"shlang.cd.disk":
			GM.AddQuestJson("shlang_cd")
			pda.AddMarker("cd_disk")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
		
		"kaizanovsky.second.group.quest":
			GM.CompleteQuest("find_kaizanovsky")
			GM.AddQuestJson("kaizanovsky_second_group")
			pda.AddMarker("second_group")
			GM.ShowPDA(true)
			GM.SaveGame() # Save Game without any story breaking
			
		"shlang.cd.zasada":
			GM.current_level.get_node("shlang_cd_zasada").position.y = 1.41
			GM.current_level.get_node("zasada_npc_1").position.y = 0.0
			GM.current_level.get_node("zasada_npc_2").position.y = 0.0
			
		"shlang.cd.found":
			pda.DeleteMarker("cd_disk")
			GM.ShowPDA(true)
			
		"shlang.complete.quest":
			gui.SkillWindow.AddExp(quests_exp_table["cd_disk"])
			GM.CompleteQuest("shlang_cd")
		
		"hootalin.skill":
			skills.AddSkillPoint()
		
		"cobold.first.dlg.done":
			if GM.current_level_id == "second_group_attack":
				GM.change_level("kaizanovsky_group2_final_underground")
			pda.DeleteMarker("second_group")
			GM.CompleteQuest("kaizanovsky_second_group")
			
		"cobold.second.dlg.done":
			GM.current_level.get_node("npc_cobold").position.y = -3.0
			GM.current_level.get_node("npc_kaizanovsky").PlayAnim("sit_ground")
			GM.current_level.get_node("npc_kaizanovsky").ChangeWeaponPosition("backpack")
			
		"kaizanovsky.dead":
			GM.current_level.get_node("npc_kaizanovsky").can_talk = false
			GM.current_level.get_node("npc_kaizanovsky").PlayAnim("sit_ground_death")
		
		"intro.cutscene":
			player.can_use = false
			player.can_look = false
			player.is_cutscene = true
			GM.Gui.SetWeaponHUD(false)
			GM.Gui.SetHUD(false)	
			
			player.ChangeRotationCutScene(Vector3(0.00, 0.52, 0.00))
			game_process.cutscene_slide_camera(Vector3(12.48, 1.44, -21.74),Vector3(5.49, 1.44, -11.03),4,5)
			await game_process.cutscene_cam_slided
			await get_tree().process_frame
			
			player.ChangeRotationCutScene(Vector3(0.01, -2.29, 0.00))
			game_process.cutscene_slide_camera(Vector3(-0.08, 0.44, -0.93),Vector3(4.49, 0.97, -7.00),6,5)
			var cutscene_player : NPC = GM.create_enemy("stalker","no_eyezone",Vector3(6.32, 0, -5.53),Vector3(0.00, 2.69, 0.00))
			cutscene_player.r_hand.hide()
			await get_tree().create_timer(4.5).timeout
			cutscene_player.PlayAnim("story_manikovsky_safe")
			
			await game_process.cutscene_cam_slided
			await get_tree().process_frame
			
			cutscene_player.queue_free()
			var sp = null
			for obj in Utility.read_json("assets/levels/"+GM.current_level_id+"/level.json")["level_data"]:
				if "id" in obj and obj["id"] == "spawn_point":
					sp = obj
					break
					
			player.ChangePosition(Vector3(sp["position"][0],sp["position"][1],sp["position"][2]))
			player.ChangeRotation(Vector3(sp["rotation"][0],sp["rotation"][1],sp["rotation"][2]))
			
			player.can_use = true
			player.can_look = true
			player.is_cutscene = false
			GM.Gui.SetWeaponHUD(true)
			GM.Gui.SetHUD(true)
			
		"final.cutscene":
			player.can_use = false
			player.can_look = false
			player.is_cutscene = true
			GM.Gui.SetWeaponHUD(false)
			GM.Gui.SetHUD(false)	
			
			GM.AddEventKey("final.cutscene.update.weapons")
			
			player.ChangeRotationCutScene(Vector3(-0.00, -0.05, 0.00))
			game_process.cutscene_slide_camera(Vector3(75.60, 1.83, 143.95),Vector3(76.74, 1.83, 143.62),4)
			
			await game_process.cutscene_cam_slided
			await get_tree().process_frame
			
			game_process.cutscene_slide_camera(Vector3(76.88, 1.07, 126.43),Vector3(75.91, 1.07, 126.35),8)
			player.ChangeRotationCutScene(Vector3(-0.00, 3.06, 0.00))
			player.ChangeFov(50.0)
			
			await game_process.cutscene_cam_slided
			await get_tree().process_frame
			
			#cutscene_slide_camera(Vector3(85.12, 16.34, 167.83),Vector3(82.27, 14.68, 162.20),1,2)
			#player.ChangeFov(15.0)
			#player.ChangeRotationCutScene(Vector3(-0.45, 0.21, 0.00))
			
			#await cutscene_cam_slided
			#await get_tree().process_frame
			
			dialogue.StartDialogue("cobold_dialogue_final","npc.kobold.name")
			
			await gui.DialogueWindow.dialogue_ended
			
			player.ChangeFov(72.0)
			player.ChangePosition(Vector3(76.96, 1.40, 143.04))
			player.ChangeRotationCutScene(Vector3(0.00, 0.19, 0.00))
			GM.current_level.get_node("player_npc").position = Vector3(76.31,-0.28,129.135)
			
			await get_tree().create_timer(1.5).timeout
			
			GM.current_level.get_node("player_npc").PlayAnim("death_stand")
			
			await get_tree().create_timer(0.1).timeout
			
			player.ChangePosition(Vector3(81.68, 0.85, 125.38))
			player.ChangeRotationCutScene(Vector3(0.00, 2.33, 0.00))
			
			await get_tree().create_timer(0.5).timeout
			player.ChangeFov(105.0)
			player.ChangeRotationCutScene(Vector3(-0.09, -2.53, 0.00))
			player.ChangePosition(Vector3(75.96, 0.74, 125.23))
			
			await get_tree().create_timer(0.2).timeout
			GM.AddEventKey("final.cutscene.shoot.stop")
			
			await get_tree().create_timer(1.0).timeout
			player.ChangeFov(72.0)
			game_process.cutscene_slide_camera(Vector3(76.51, 2.17, 126.85),Vector3(76.49, 3.92, 128.34),2,2)
			player.ChangeRotationCutScene(Vector3(-0.09, -2.53, 0.00))
			game_process.cutscene_rotate_camera(Vector3(-0.09, -2.94, 0.00),Vector3(0.56, -2.94, 0.00),8)
			
			await get_tree().create_timer(0.5).timeout
			
			GM.Gui.final_image.show()
			await game_process.cutscene_cam_slided
			await get_tree().process_frame
			
			game_process.cutscene_camera_rotation = false
			
			await get_tree().create_timer(1.5).timeout
			
			GM.ambient_system.MainMenuAmbientOff()
			dialogue.StartDialogue("ghost_dialogue","npc.prizrak.name")
		
		"final.cutscene.update.weapons":
			# get names of npc's on levels (nodes with names betrayer)
			var betrayers = ["betrayer1","betrayer2","betrayer3","betrayer4","betrayer5"]
			for b in betrayers:
				# resetting weapons models in their hands
				GM.current_level.get_node(b).ChangeWeaponPosition("r_hand")
				
		"final.cutscene.shoot":
			var betrayers = ["betrayer1","betrayer2","betrayer3","betrayer4","betrayer5"]
			for b in betrayers:
				# all npc's play shoot animation but with different delay
				GM.current_level.get_node(b).PlayAnim("shoot_stand_idle_cutscene")
				await get_tree().create_timer(randf_range(0.2,0.5)).timeout
				
		"final.cutscene.shoot.stop":
			var betrayers = ["betrayer1","betrayer2","betrayer3","betrayer4","betrayer5"]
			for b in betrayers:
				# stop shooting
				GM.current_level.get_node(b).animation.stop()
				GM.current_level.get_node(b).PlayAnim("weapon_stand_idle_story")
				await get_tree().create_timer(randf_range(0.1,0.3)).timeout
				
		"the.end":
			# turn off ambient, cause when we shows us death screen
			# level will be unload, so we need stop it's ambient for silence
			GameManager.ambient_system.MainMenuAmbientOff()
			# Show TO BE CONTINUED screen (it's literaly death screen :p)
			player.Death()
			await get_tree().create_timer(0.3).timeout
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			player.can_use = true
			player.can_look = true
			player.is_cutscene = false
			GM.Gui.SetWeaponHUD(true)
			GM.Gui.SetHUD(true)

# Call when any dialogue start, argument - ID of opened dialogue
func on_dialogue_start(id):
	pass
	
# Call when any dialogue ends, argument - ID of closed dialogue
func on_dialogue_end(id):
	pass
	
# Call when any item from lootbox was took, argument - ID of item
func on_loot_item_took(id):
	var lvl = GM.current_level_id
	# GALOSH ARTEFACT QUEST
	if id == "af_medusa" and lvl == "galosh_art":
		GM.AddEventKey("loot.galosh.art.found")
	# BATKA BATTERY QUEST		
	if id == "af_battery" and lvl == "batka_find_battery":
		GM.AddEventKey("loot.batka.art.found")
	
# Call when any door was used ID:(transition, transition_to_level), argument - Dict{} of level object data
func on_door_used(door_data):
	match door_data["name"]:
		# doors at bandits campt to jellyfish artefact room
		"transition_zone3": 
			if GM.current_level_id == "galosh_art":
				GM.ambient_system.init_ambient("garbage_camp")
				
		"transition_zone_back_to_outdoor":
			GM.ambient_system.init_ambient("galosh_art")
		
		# returning wp for batka_battery
		"transition_zone_battery9": 
			GM.current_level.get_node("transition_zone_battery8").hide()
			game_process._get_transition_trigger("transition_zone_battery11").keys["waypoints"] = "battery_wp11"
		"transition_zone_battery11":
			game_process._get_transition_trigger("transition_zone_battery7").keys["waypoints"] = "battery_wp9"
		"transition_zone_battery12":
			game_process._get_transition_trigger("transition_zone_battery10").keys["waypoints"] = "battery_wp12"
		"transition_zone7_tozasada":
			GM.current_level.get_node("transition_zone7_tozasada").position.y = -3.0
	
# Call when player came to any eyezone	
func come_in_eyezone(eyezone : EYEZONE):
	print("player came to %s eyezone!" % eyezone.id)
	if GM.current_level_id == "city_alley":
		if eyezone.id == "eyezone_merc_3": # the last eyezone in the city for ambush
			GM.current_level.get_node("npc_merc_hided").position = Vector3(16.249,0,-37.281)
			GM.current_level.get_node("last_transition").position = Vector3(25.103,-2.404,-33.298)
# Call when player out from any eyezone
func out_from_eyezone(eyezone : EYEZONE):
	pass

# Call when NPC played animation and it was finished
func on_npc_animation_finished(npc : NPC, anim_name : String):
	#if npc.id == "someones_profile":
	#	match anim_name:
	#		"animation_name": GM.AddEventKey("test.event.key")
	if npc.id == "manikovsky_profile":
		match anim_name:
			"story_manikovsky_safe": GM.DeleteEventKey("manikovsky.dialogue.done")
