extends ColorRect

@onready var mm : MainMenu = $"../GAME/MainMenu"
@onready var title : Label = $CenterContainer/title
@onready var press_title : Label = $press_enter_title

func close_death_screen():
	if GameManager.Gui.final_image.visible:
		GameManager.Gui.final_image.hide()
	#await get_tree().create_timer(0.2).timeout
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_pause_mainmenu_click"])
	await get_tree().create_timer(0.2).timeout
	if GameManager.current_level != null:
		GameManager.current_level.queue_free()
		GameManager.current_level = null
	
	GameManager.ambient_system.MainMenuAmbientOff()
	
	GameManager.player.SetHealth(1)
	GameManager.player.is_dead = false
	GameManager.pause = false
	GameManager.main_menu = true
	if not GameManager.show_splash:
		GameManager.player.PlayMusic("assets/sounds/mm_music.wav")
	GameManager.WipePlayerData()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.hide()
	GameManager.Gui.MainMenuWindow.show()			

func _on_visibility_changed():
	if GameManager.player and GameManager.player.is_dead:
		if self.visible:
			GameManager.ambient_system.MainMenuAmbientOff()
			if GameManager.Gui.PauseWindow.visible:
				GameManager.Gui.PauseWindow.Close()
			if GameManager.HasEventKey("the.end"):
				title.text = Lang.translate("to.be.continued")
			else:
				title.text = Lang.translate("gameover")
		


func _on_press_enter_title_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close_death_screen()


func _on_press_enter_title_mouse_entered():
	press_title.add_theme_color_override("font_color",Color("ee9d31"))


func _on_press_enter_title_mouse_exited():
	press_title.add_theme_color_override("font_color",Color("66625f"))
