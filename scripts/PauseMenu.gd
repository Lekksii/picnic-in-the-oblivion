class_name PauseMenu extends ColorRect

@export var buttons_list : Control 
var need_open : bool = true

func _on_continue_pressed():
	ContinueGame()


func _on_mainmenu_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_mainmenu_click"])
	await get_tree().create_timer(0.2).timeout
	if GameManager.current_level != null:
		GameManager.current_level.queue_free()
		GameManager.current_level = null
	GameManager.Gui.MainMenuWindow.show()
	GameManager.player.SetHealth(10)
	GameManager.player.is_dead = false
	GameManager.pause = false
	GameManager.main_menu = true
	
	GameManager.ambient_system.MainMenuAmbientOff()
	#if not GameManager.show_splash:
	
	GameManager.player.PlayMusic("assets/sounds/mm_music.wav")
	
	GameManager.WipePlayerData()
	Close()
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_inventory_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_inv_click"])
	GameManager.Gui.InventoryWindow.is_open_from_pause = true
	await get_tree().create_timer(0.1).timeout
	GameManager.Gui.InventoryWindow.Open()
	hide()


func _on_character_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_character_click"])
	#await get_tree().create_timer(0.1).timeout
	GameManager.Gui.SkillWindow._update_skills()
	GameManager.Gui.SkillWindow.is_open_from_pause = true
	GameManager.Gui.SkillWindow.Open()
	#self.hide()
	#self.set_process_input(false)

func _on_map_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_map_click"])
	
	GameManager.Gui.MapWindow.is_open_from_pause = true
	await get_tree().create_timer(0.1).timeout
	GameManager.Gui.MapWindow.Open()
	hide()


func _on_journal_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_journal_click"])
	#await get_tree().create_timer(0.1).timeout
	GameManager.Gui.JournalWindow.is_open_from_pause = true
	GameManager.Gui.JournalWindow.Open()
#self.hide()

func ContinueGame():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_resume_click"])
	
	Close()

func Close():
	GameManager.pause = false
	if not GameManager.Gui.death_screen.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
	if not GameManager.ai_ignore:
		if GameManager.player.current_eyezone != null:
			if GameManager.player.current_eyezone.enemies.size() > 0:
				for e in GameManager.player.current_eyezone.enemies:
					e.delay_timer = e._temp_old_delay
					e.can_attack = false
				var ai =  GameManager.player.current_eyezone.enemies.pick_random()
				#ai.delay_timer = 2.0
				ai.can_attack = true
				
	#print("pause closed")
	

func Open():
	if not GameManager.pause and not visible:
		GameManager.pause = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		show()
		GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_open"])
		

func CloseWindowQuickly(window):
	GameManager.pause = false
	if not GameManager.Gui.death_screen.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	window.hide()

func _process(delta):
	if not GameManager.is_game_ready: return
	
	if GameManager.Gui.death_screen.visible:
		Close()
	
	if (Input.is_action_just_pressed("pause") and
	not GameManager.main_menu and 
	not GameManager.player.is_dead and 
	not GameManager.player.waypoint_walk and 
	not GameManager.weapon_system.is_reloading and 
	not GameManager.player.is_cutscene and 
	not GameManager.Gui.TradingMessage.visible and 
	not GameManager.Gui.DialogueWindow.visible):
		if self.visible and all_windows_closed():
			if GameManager.level_is_safe:
				GameManager.SaveGame()
			Close()
			return
		else:
			if GameManager.Gui.InventoryWindow.IsOpened():
				if GameManager.Gui.InventoryWindow.is_open_from_pause:
					if GameManager.level_is_safe:
						GameManager.SaveGame()
					GameManager.Gui.InventoryWindow.Close()
				
			if GameManager.Gui.JournalWindow.IsOpened():
				if GameManager.Gui.JournalWindow.is_open_from_pause:
					if GameManager.level_is_safe:
						GameManager.SaveGame()
					GameManager.Gui.JournalWindow.Close()
				
			if GameManager.Gui.MapWindow.IsOpened():
				if GameManager.Gui.MapWindow.is_open_from_pause:
					if GameManager.level_is_safe:
						GameManager.SaveGame()
					GameManager.Gui.MapWindow.Close()
				
			if GameManager.Gui.SkillWindow.IsOpened():
				if GameManager.Gui.SkillWindow.is_open_from_pause:
					if GameManager.level_is_safe:
						GameManager.SaveGame()
					GameManager.Gui.SkillWindow.Close()
					
			if GameManager.Gui.Loot.IsOpened():
				GameManager.Gui.Loot.Close()
				return
				
			if GameManager.Gui.SpawnMenuWindow.visible:
				GameManager.Gui.SpawnMenuWindow.hide()
				return
				
			if GameManager.Gui.MainMenuWindow.visible:
				if GameManager.Gui.MainMenuWindow.options_menu.visible:
					_on_back_to_pause_pressed()
				
		
		if not (GameManager.Gui.TipWindow.visible and 
		GameManager.Gui.DialogueWindow.IsOpened() and 
		GameManager.Gui.TradingWindow.IsOpened() and 
		GameManager.Gui.IntroWindow.visible and 
		GameManager.Gui.death_screen.visible):
			if not GameManager.pause and need_open:
				Open()
				return
		if not need_open:
			need_open = true
			return

func all_windows_closed() -> bool:
	return (not GameManager.Gui.InventoryWindow.IsOpened() and 
			not GameManager.Gui.JournalWindow.IsOpened() and 
			not GameManager.Gui.MapWindow.IsOpened() and 
			not GameManager.Gui.SkillWindow.IsOpened() and
			not GameManager.Gui.SpawnMenuWindow.visible and
			not GameManager.Gui.MainMenuWindow.visible)
func _on_visibility_changed():
	if GameManager.pda_enabled:
		$VerticalContainer/map.disabled = false
	else:
		$VerticalContainer/map.disabled = true
	
	for children in buttons_list.get_children():
			if children.has_node("AnimIcon"):
				children.get_node("AnimIcon").hide()


func _on_options_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_options_click"])
	GameManager.Gui.MainMenuWindow.show()
	GameManager.Gui.MainMenuWindow.options_menu.show()
	GameManager.Gui.MainMenuWindow.options_menu.get_node("back").hide()
	GameManager.Gui.MainMenuWindow.options_menu.get_node("back_to_pause").show()
	GameManager.Gui.MainMenuWindow._update_options()


func _on_back_to_pause_pressed():
	GameManager.Gui.MainMenuWindow.hide()
	GameManager.Gui.MainMenuWindow.options_menu.hide()
	GameManager.Gui.MainMenuWindow.options_menu.get_node("back").show()
	GameManager.Gui.MainMenuWindow.options_menu.get_node("back_to_pause").hide()
