extends Control

@export var _move_to: Control

@export var _initial_delay: float = 1

var _splash_screens: Array[SplashScreen] = []

@onready var _splash_screen_container: Control = $"."
@onready var _splash_blocker : ColorRect = $"../SplashBlocker"
@onready var mm : MainMenu = $"../GAME/MainMenu"

func _ready() -> void:
	if GameManager.main_menu and GameManager.show_splash:
		if not self.visible:
			self.show()
			_splash_blocker.show()
			_move_to.hide()
		assert(_move_to)

		set_process_input(false)

		for splash_screen in _splash_screen_container.get_children():
			splash_screen.hide()
			_splash_screens.push_back(splash_screen)

		await get_tree().create_timer(_initial_delay).timeout

		_start_splash_screen()

		set_process_input(true)


func _input(_event: InputEvent) -> void:
	if GameManager.main_menu and GameManager.show_splash:
		if OS.has_feature('windows'):
			if Input.is_action_just_pressed("pause"):
				_skip()
		
		if OS.has_feature('mobile'):
			if _event is InputEventScreenTouch:
				if _event.is_pressed():
					_skip()

func _start_splash_screen() -> void:
	if _splash_screens.size() == 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_move_to.show()
		_splash_blocker.queue_free()
		self.queue_free()
		mm.OnSplashFinishedAll()
	else:
		if not GameManager.Gui.death_screen.visible and not GameManager.Gui.MainMenuWindow.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var splash_screen: SplashScreen = _splash_screens.pop_front()
		_splash_blocker.color = splash_screen.color
		splash_screen.start()
		splash_screen.connect("finished", _start_splash_screen)


func _skip() -> void:
	_splash_screen_container.get_child(0).queue_free()
	_start_splash_screen()
