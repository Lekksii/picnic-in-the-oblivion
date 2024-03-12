extends Node

# Called that function once before game loads, gives possibility to change some games variables
# before they will affect on the game, such as enabling/disabling splash or main menu on app start.

# WARNING, some changes here can crash the game, cause this function is calls BEFORE anything load.
# So keep in mind, that you can change here only variables, do not try to change something other!
func game_init():
	GameManager.show_splash = true
	GameManager.main_menu = true
	GameManager._spawn_menu = true
	
	# we need await until game will be ready, 'cause before GameProcess variable is null
	await GameManager.on_game_ready
	
	GameManager.GameProcess.show_tutorial = true
	pass
