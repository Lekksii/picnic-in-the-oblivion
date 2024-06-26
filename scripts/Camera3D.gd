## Camera3D it's Player class, that control our player object
extends Node3D
class_name Player

# Modifier keys' speed multiplier
const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

@export_range(0.0, 1.0) var sensitivity: float = 0.25

# our camera 3D node in world
@export var PlayerCamera : Camera3D
# player head node for animations
@export var PlayerHead : Node3D
# player's fake head to calculate look_at() 
@export var FakeHead : Node3D
# array of player's footsteps 
@export var footsteps : Array[AudioStreamWAV]
# node with our sprite 3D hud
@export var WeaponHUD : Sprite3D
# show/not show debug info on hud
@export var debug_info = false
# node of weapon shot sparkle
@onready var WeaponWM : Sprite3D = $Head/PlayerCamera/WM

#dev test, one hit one kill
var one_hit_kill = false
# on/off player possibility to debug fly (KEEP IN MIND, THAT KILLING ENEMIES IN THIS MODE ALLOW SOFTLOCK OF THE GAME)
@export var DebugFly : bool = true
# on/off camera sway on mouse motion to the left/right
var camera_sway_option = true

# current eyezone of enemy attacks (if player in this eye zone - enemies attached to this zone will attack)
var current_eyezone
# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
#var _total_yaw = 0.0
var in_focus = false

signal in_eyezone
signal out_from_eyezone
signal dead

var camera_input : Vector2
var rotation_velocity : Vector2

# curves for procedural animations for recoil
@export var recoil_pos_curves: Array[Curve] = []
@export var recoil_rot_curves: Array[Curve] = []

# is player walking by waypoints?
var waypoint_walk : bool = false
# waypoint index
var point = 0
# next level where we will spawned after we'll arrive to the last point
var waypoint_new_level : String = ""
# end position of last waypoint
var waypoint_end_position = Vector3()
# keys data from level.json of current level of currently used door trigger
var transition_data = null
# is cutscene now enabled?
var is_cutscene = false

# recoil settings, probably all works good, don't touch
var recoil_duration := 0.8
var recoil_timer := 0.0
var is_recoiling := false
var recoil_min := -1
var recoil_max := 1
var recoil_x = 0
var recoil_y = 0
var recoil_z = 0

# on/off posibility to rotate camera by mouse, useful to block mouse in cutscenes and waypoints walking
var can_look = true
# on/off posibility to interact
var can_use = true

# recoil settings, probably all works good, don't touch
@export var use_recoil_pos_x := true
@export var use_recoil_pos_y := true
@export var use_recoil_pos_z := true

@export var use_recoil_rot_x := true
@export var use_recoil_rot_y := true
@export var use_recoil_rot_z := true

var last_recoil_dir := 1.0
var recoil_force_pos: Vector3 = Vector3.ZERO
var recoil_force_rot: Vector3 = Vector3.ZERO

# on/off footsteps playing sounds
var can_play_footstep = false

# mouse smoothnes (now it's cuted, couse it may have some bugs with mouse)
var SMOOTHNESS = 12
# mouse sensitivity
var SENSITIVITY = 0.19
# camera bob settings
var BOB_FREQ = 3.0
var BOB_AMP = 0.04
var t_bob = 0.0
# delay between shots (get's data from gameplay/weapons.json)
var SHOOT_DELAY = 0.1
# timer
var shoot_delay_timer = 0.1
# is ready to shoot?
var ready_to_shoot = false
# original positions of hud data for procedural sway animations and reseting position
var hud_orig_pos : Vector3 = Vector3.ZERO
var hud_orig_wm_pos : Vector3 = Vector3.ZERO
# Movement state
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4

# Keyboard state
var _w = false
var _s = false
var _a = false
var _d = false
var _q = false
var _e = false
var _shift = false
var _alt = false

# Game vars
var health : float = 1.0
var health_max : float = 1.0

var money : int = 0
# if true, radiation zone don't affect on you
var antirad : bool = false
# if true, radiation zone hit's you every *radiation_timer* seconds.
var radiation : bool = false
var radiation_timer = 5.0
# if *antirad* is true, this timer starts to tick
var antirad_timer = 20.0
# fov of the game, basicaly it's don't affects the hud, so don't change it
var fov = 76
var basic_fov = 1
# raycast node of player
@export var raycast : RayCast3D
@export var hud : Sprite3D
@export var timer : Timer
@export var shoot_fire : Sprite3D
@onready var hud_anim_player : AnimationPlayer = $Head/PlayerCamera/HUD/AnimationPlayer
# AUDIO
@onready var audio : AudioStreamPlayer = $Head/PlayerCamera/sfx1
@onready var audio_sfx : AudioStreamPlayer = $Head/PlayerCamera/sfx2
@onready var music : AudioStreamPlayer = $Head/PlayerCamera/music
@onready var flashlight : SpotLight3D = $Head/PlayerCamera/Flashlight
var is_dead = false
var rad_geiger_playing = false
var rad_geiger_current_sfx = null
var last_point_pos = null
var last_point_rot = null

signal player_loaded

# ДИАПАЗОН ПОВОРОТА ПО [Y]
var rotation_range_y = [-60, 60]

# init game player
func game_init():
	if not debug_info:
		GameManager.Gui.timers_text.text = ""
	basic_fov = fov
	add_to_group("player")
	get_node("/root/Game").call_deferred_thread_group("main_game_init")
	ChangeFov(basic_fov)

# some fixes with game focus
func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_cutscene:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				await get_tree().create_timer(0.1).timeout
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if OS.has_feature('mobile'):
				if GameManager.main_menu and GameManager.Gui.MainMenuWindow.visible and ( 
				not GameManager.Gui.MainMenuWindow.about_menu.visible and
				not GameManager.Gui.MainMenuWindow.options_menu.visible and 
				not GameManager.Gui.IntroWindow.visible):
					get_tree().quit()
				else:
					Input.action_press("pause")
					await get_tree().create_timer(0.1).timeout
					Input.action_release("pause")
			
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not is_cutscene:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if (not GameManager.pause and not GameManager.Gui.TradingWindow.IsOpened()):
				Input.action_press("pause")
				Input.action_release("pause")
				
		NOTIFICATION_WM_CLOSE_REQUEST:
			GameJolt.sessions_close()

func game_input(_event):
	pass
# game update (process)
func game_update(delta):
	
	if debug_info:
		GameManager.Gui.timers_text.text = "Antirad: %.1f\nRad: %.1f" % [antirad_timer, radiation_timer]
	if not ready_to_shoot:
		reset_shoot(delta)
		
	# antirad feature
	if antirad and not GameManager.pause and not waypoint_walk:
		GameManager.Gui.ShowRad()
		_update_rad_visual()
		antirad_timer -= delta
		if antirad_timer <= 0:
			antirad = false
			GameManager.Gui.HideRad()
			antirad_timer = 20.0
	
	# radiation feature
	if radiation:
		if !rad_geiger_playing:
			rad_geiger_playing = true
		else:
			if rad_geiger_current_sfx == null:
				rad_geiger_current_sfx = GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["geiger_sound"].pick_random() if typeof(GameManager.sfx_manager_json["geiger_sound"]) == TYPE_ARRAY else GameManager.sfx_manager_json["geiger_sound"],-30)
	else:
		if rad_geiger_current_sfx != null:
			if rad_geiger_current_sfx.volume_db > -80:
				rad_geiger_current_sfx.volume_db -= linear_to_db(delta*64)
			else:
				rad_geiger_current_sfx.queue_free()
			
	# RADIATION AFFECTING ON PLAYER
	if radiation and not antirad and not GameManager.pause and not waypoint_walk and \
	GameManager.Gui.SkillWindow.radiation_resistance < 100.0:
		
		radiation_timer -= delta
		if radiation_timer <= 0:
			var skill = GameManager.Gui.SkillWindow as SkillSystem
			var rad_dmg = 5.0
			var rad_resistance_dmg = rad_dmg*(100.0-skill.radiation_resistance)/100.0
			var anom_resistance_dmg = rad_dmg*(100.0-skill.anomaly_resistance)/100.0
			var final_damage = rad_resistance_dmg + anom_resistance_dmg
			GameManager.Gui.damage_l.show()
			GameManager.Gui.damage_r.show()
			Hit(final_damage)
			radiation_timer = 5.0
			if GameManager.first_rad_damage:
				GameManager.first_rad_damage = false
				if OS.has_feature("windows"):
					GameManager.GameProcess._show_tutorial("radiation_tip")
				if OS.has_feature("mobile"):
					GameManager.GameProcess._show_tutorial("radiation_tip_mob")
					
			
	get_node("/root/Game").main_game_update(delta)

# play audio from file
func PlayAudio(stream : AudioStreamPlayer,file):
	var audio_loader = AudioLoader.new()
	stream.set_stream(audio_loader.loadfile(GameManager.app_dir+file))
	#audio.volume_db = 1
	#audio.pitch_scale = 1
	stream.play()

# play hud animation
func PlayHudAnimation(anim):
	hud_anim_player.play(anim)
	
func PlaySFX(path):
	PlayAudio(audio_sfx,path)
	
func PlaySFX2(path):
	PlayAudio(audio,path)

## Play music
func PlayMusic(path):
	var audio_loader = AudioLoader.new()
	music.set_stream(audio_loader.loadfile(GameManager.app_dir+path))
	music.play()
	
func AddMoney(value : int, with_message : bool = false):
	money += value
	if with_message:
		GameManager.Gui.ShowMessage("%d$" % value)
	_update_money()
	
func LowMoney(value : int):
	money -= value
	_update_money()
	
func SetMoney(value : int):
	money = value
	_update_money()
	
func _update_money():
	GameManager.Gui.InventoryMoney.text = str(money)+"$"
	
#### GAMEPLAY START ####
## Loading player profile
func LoadPlayerProfile():
	var data = GameManager.player_json
	#var quests_data = GameManager.quests_json
	SetMaxHp(data["start_max_hp"])
	SetHealth(health_max)
	SetMoney(data["start_money"])
	
	if "start_skills" in data:
		if "accuracy" in data["start_skills"]:
			GameManager.Gui.SkillWindow.accuracy = data["start_skills"]["accuracy"]
		if "strength" in data["start_skills"]:
			GameManager.Gui.SkillWindow.strenght = data["start_skills"]["strength"]
		if "armor" in data["start_skills"]:
			GameManager.Gui.SkillWindow.armor = data["start_skills"]["armor"]
		if "rad_resist" in data["start_skills"]:
			GameManager.Gui.SkillWindow.radiation_resistance = data["start_skills"]["rad_resist"]
		if "anom_resist" in data["start_skills"]:
			GameManager.Gui.SkillWindow.anomaly_resistance = data["start_skills"]["anom_resist"]
			
	GameManager.Gui.InventoryWindow.weight_max = data["max_weight"]
	GameManager.Gui.SkillWindow._update_skills()
	GameManager.Gui.loading_screen.show()
	#GameManager.load_level("garbage_camp")
	await get_tree().create_timer(0.1).timeout
	
	GameManager.Gui.loading_screen.hide()
	
	for i in data["start_items"]:
		GameManager.Gui.InventoryWindow.AddItem(i)
		
	for use in data["use_items_after_start"]:
		if GameManager.Gui.InventoryWindow.Find(use):
			GameManager.Gui.InventoryWindow.Find(use).UseItem()
			
	for e_key in data["start_event_keys"]:
		GameManager.AddEventKey(e_key)
		
	for quest in data["start_quests"]:
		GameManager.AddQuestJson(quest)
	var audioloader = AudioLoader.new()
	
	player_loaded.emit()
	
	await GameManager.on_game_ready
	
	if GameManager.casual_gameplay:
		if "casual_mode" in data:
			if "accuracy" in data["casual_mode"]:
				GameManager.Gui.SkillWindow.accuracy = data["casual_mode"]["accuracy"]
			if "stength" in data["casual_mode"]:
				GameManager.Gui.SkillWindow.strenght = data["casual_mode"]["strength"]
		else:
			GameManager.Gui.SkillWindow.accuracy = 0.75
			GameManager.Gui.SkillWindow.strenght = 3
	#GameManager.AddEventKey("dev.test.red")
	#GameManager.Gui.DialogueWindow.StartDialogue("test_deditor","")
### ----------------------------------------------- ###
func _input(event):
	#if not in_focus:
	#	return
	if can_look:
		if OS.has_feature('windows'):
			if event is InputEventMouseMotion:
				#print("mouse motion!")
				_mouse_position = event.relative
		if OS.has_feature('mobile'):
			if event is InputEventScreenDrag:
				#print("touchscreen motion!")
				#print(event.relative)
				_mouse_position = event.relative
			
	game_input(event)
	# Receives mouse motion
	
		#print(_mouse_position)
	
	# Receives mouse button input
	#if event is InputEventMouseButton:
	#	match event.button_index:
	#		MOUSE_BUTTON_RIGHT: # Only allows rotation if right click down
	#			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
	#		MOUSE_BUTTON_WHEEL_UP: # Increases max velocity
	#			_vel_multiplier = clamp(_vel_multiplier * 1.1, 0.2, 20)
	#		MOUSE_BUTTON_WHEEL_DOWN: # Decereases max velocity
	#			_vel_multiplier = clamp(_vel_multiplier / 1.1, 0.2, 20)

	# Receives key input
	if event is InputEventKey:
		match event.keycode:
			KEY_W:
				_w = event.pressed
			KEY_S:
				_s = event.pressed
			KEY_A:
				_a = event.pressed
			KEY_D:
				_d = event.pressed
			KEY_Q:
				_q = event.pressed
			KEY_E:
				_e = event.pressed
			KEY_SHIFT:
				_shift = event.pressed
			KEY_ALT:
				_alt = event.pressed

func _physics_process(delta):
	pass

func lerp_angle(a, b, t):
	return a + shortest_angle(a, b) * t

func shortest_angle(a, b):
	var angle = (b - a) % (2 * PI)
	if angle < -PI:
		angle += 2 * PI
	elif angle > PI:
		angle -= 2 * PI
	return angle

func camera_sway(x,delta,weight:float):
	if camera_sway_option:
		PlayerHead.rotation.z = lerp(PlayerHead.rotation.z,-x/5, delta* weight)

func _headbob_nosnd(time) -> Vector3:
	var pos = Vector3.ZERO
	#var low_pos = BOB_AMP - 0.01
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP

	return pos

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	var low_pos = BOB_AMP - 0.01
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	
	#print(pos.y)
	
	if pos.y > -low_pos:
		can_play_footstep = true
		
	if pos.y < -low_pos and can_play_footstep:
		play_random_footstep()
		can_play_footstep = false
	
	return pos

func _wpn_system_play_shot(b:bool):
	GameManager.weapon_system._show_wm_sarkle(b)

func play_random_footstep():
	var sound = preload("res://engine_objects/footstep.tscn").instantiate()
	sound.stream = footsteps.pick_random()
	audio_sfx.add_child(sound)
	sound.play()

# Updates mouselook and movement every frame
func _process(delta):
	game_update(delta)
	
	if not GameManager.is_game_ready: return
	if is_dead: return
	
	if DebugFly and not GameManager.Gui.ConsoleWindow.visible: _update_movement(delta)
	
	if GameManager.waypoints.curve == null:
		reset_pos_rot(delta)
	
	if waypoint_walk:
		t_bob += delta * 3 * float(waypoint_walk)
	
	if GameManager.waypoints.curve != null:
		
		if waypoint_walk:
			
			GameManager.Gui.crosshair.hide()
			GameManager.Gui.press_f_text.hide()
			can_look = false
			can_use = false
			if hud_anim_player.current_animation == "wpn_idle" or \
			hud_anim_player.current_animation == "shoot":
				PlayHudAnimation("walk")
				hud_anim_player.speed_scale = 0.60
			#if not GameManager.waypoints.get_node("follower").has_node("Player"):
			#	self.reparent(GameManager.waypoints.get_node("follower"),true)
			#	self.position = Vector3.ZERO
			
			if GameManager.waypoints.curve.point_count > 0:		
				# player simulating walking camera effect
				PlayerCamera.rotation.x = _headbob(t_bob).x
				
				#var new_pos = Vector3(waypoint_end_position.position.x,waypoint_end_position.position.y,waypoint_end_position.position.z)
				var destination = GameManager.waypoints.curve.get_point_position(point)
				global_position = global_position.move_toward(destination,delta * 2.3)
				#camera_sway(PlayerHead.rotation.y,delta,0.8)
				#print(PlayerHead.rotation.z)
				if global_position.distance_to(destination) <= 0.15:
					
					if point < GameManager.waypoints.curve.point_count-1:
						point += 1
						#print(point)
					else:
						last_point_rot = destination
						print(last_point_rot)
						GameManager.waypoints.curve.clear_points()
					camera_sway(0.0,delta,0.8)
				else:
					#print("Point: %s / %s" % [str(point),str(GameManager.waypoints.curve.point_count-1)])
					if point != GameManager.waypoints.curve.point_count-1:
						FakeHead.look_at(destination)
						
						PlayerHead.rotation.y = lerp_angle(PlayerHead.rotation.y,FakeHead.rotation.y,delta * 2)
						PlayerCamera.rotation.y = lerp_angle(PlayerCamera.rotation.y,FakeHead.rotation.y,delta * 2)
					else:
						var new_pos = GameManager.waypoints.curve.get_point_position(point)
						#FakeHead.rotation = Vector3.ZERO
						FakeHead.look_at(new_pos)
						PlayerCamera.rotation.x = lerp_angle(PlayerCamera.rotation.x,FakeHead.rotation.x,delta * 2)
						PlayerCamera.rotation.y = lerp_angle(PlayerCamera.rotation.y,FakeHead.rotation.y,delta * 2)
						PlayerCamera.rotation.z = lerp_angle(PlayerCamera.rotation.z,FakeHead.rotation.z,delta * 2)
						
			else:
				GameManager.waypoints.curve = null
				GameManager.Gui.crosshair.show()
				GameManager.Gui.press_f_text.show()
				waypoint_walk = false
				point = 0
				#await get_tree().create_timer(0.1).timeout
				if transition_data["id"] == "transition_to_level":
					GameManager.LoadGameLevel(waypoint_new_level)
					GameManager.on_door_used.emit(transition_data)
					
				
				if "target_object" in transition_data and transition_data["target_object"] != "" and not transition_data["last_point_is_end"]:
					ChangeRotation(GameManager.current_level.get_node(transition_data["target_object"]).rotation_degrees)
					ChangePosition(GameManager.current_level.get_node(transition_data["target_object"]).position)
				else:
					if transition_data["id"] == "transition":
						if "target_rotation" in transition_data:
							ChangeRotation(Vector3(transition_data["target_rotation"][0],transition_data["target_rotation"][1],transition_data["target_rotation"][2]))
						if "last_point_is_end" in transition_data and transition_data["last_point_is_end"]:
							#var y_direction : float = Vector2(last_point_rot.z.x,last_point_rot.z.z).angle_to(Vector2(0,-1))
							#print(y_direction)
							FakeHead.look_at(last_point_rot)
							ChangePosition(last_point_pos)
							ChangeRotation(Vector3(0.0,FakeHead.rotation_degrees.y,0.0))
							FakeHead.rotation = Vector3.ZERO
							
						else:
							ChangePosition(Vector3(transition_data["target_position"][0],transition_data["target_position"][1],transition_data["target_position"][2]))
				GameManager.on_door_used.emit(transition_data)
				#PlayerHead.rotation = Vector3.ZERO
				#if "last_point_is_end" in transition_data and transition_data["last_point_is_end"]:
				#	FakeHead.look_at(-last_point_pos)
				#	PlayerCamera.rotation.x = lerp_angle(PlayerCamera.rotation.x,FakeHead.rotation.x,delta * 2)
				#	PlayerCamera.rotation.y = lerp_angle(PlayerCamera.rotation.y,FakeHead.rotation.y,delta * 2)
				#	PlayerCamera.rotation.z = lerp_angle(PlayerCamera.rotation.z,FakeHead.rotation.z,delta * 2)

				PlayerCamera.rotation = Vector3.ZERO
				PlayerHead.rotation = Vector3.ZERO
				FakeHead.rotation = Vector3.ZERO
				_total_pitch = 0
				can_look = true
				can_use = true
				if hud_anim_player.current_animation == "walk":
					hud_anim_player.stop()
					PlayHudAnimation("wpn_idle")
				if hud_anim_player.current_animation.contains("reload"):
					await hud_anim_player.animation_finished
					PlayHudAnimation("wpn_idle")
				else:
					PlayHudAnimation("wpn_idle")
				hud_anim_player.speed_scale = 0.4
	
	# Only rotates mouse if the mouse is captured
	if OS.has_feature('windows'):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			
			rotation_velocity = rotation_velocity.lerp(_mouse_position * SENSITIVITY, 1) #delta * SMOOTHNESS
			
			var yaw = rotation_velocity.x
			var pitch = rotation_velocity.y
			
			# Prevents looking up/down too far
			pitch = clamp(pitch, -70 - _total_pitch, 70 - _total_pitch)
			_total_pitch += pitch
		
			rotate_y(deg_to_rad(-yaw))
			PlayerCamera.rotate_x(deg_to_rad(-pitch))
			
			# WEAPON SWAY
			if WeaponHUD.position.x < 0.01 or WeaponHUD.position.x > -0.01:
				WeaponHUD.position.x = lerp(WeaponHUD.position.x,-yaw,0.001 * delta)
				WeaponWM.position.x = lerp(WeaponWM.position.x,-yaw,0.005 * delta)
			
			camera_sway(yaw,delta,0.13)

			_mouse_position = Vector2.ZERO	
			recoil(delta)
			
	if OS.has_feature('mobile'):
		if _mouse_position != Vector2.ZERO:
			rotation_velocity = rotation_velocity.lerp(_mouse_position * SENSITIVITY, 1) #delta * SMOOTHNESS
				
			var yaw = rotation_velocity.x
			var pitch = rotation_velocity.y
			
			# Prevents looking up/down too far
			pitch = clamp(pitch, -70 - _total_pitch, 70 - _total_pitch)
			_total_pitch += pitch
		
			rotate_y(deg_to_rad(-yaw))
			PlayerCamera.rotate_x(deg_to_rad(-pitch))
			
			# WEAPON SWAY
			if WeaponHUD.position.x < 0.01 or WeaponHUD.position.x > -0.01:
				WeaponHUD.position.x = lerp(WeaponHUD.position.x,-yaw,0.001 * delta)
				WeaponWM.position.x = lerp(WeaponWM.position.x,-yaw,0.005 * delta)
			
			camera_sway(yaw,delta,0.01)

			_mouse_position = Vector2.ZERO	
			recoil(delta)
		
func reset_pos_rot(delta: float) -> void:
	if not waypoint_walk and not is_cutscene:
		PlayerHead.rotation = lerp(PlayerHead.rotation,Vector3.ZERO,delta*4)
		
		if hud_orig_pos != Vector3.ZERO:
			WeaponHUD.position = lerp(WeaponHUD.position,hud_orig_pos,delta*4)
			
		if hud_orig_wm_pos != Vector3.ZERO:
			WeaponWM.position = lerp(WeaponWM.position,hud_orig_wm_pos,delta*4)
		#GameManager.player.hud.rotation = lerp(GameManager.player.hud.rotation,Vector3.ZERO,delta*8)
		#if GameManager.weapon_system.current_weapon:
		#	GameManager.player.hud.position = lerp(GameManager.player.hud.position, GameManager.weapon_system.current_weapon.hud_pos,delta*8)
	if waypoint_walk:
		PlayerHead.rotation.z = lerp(PlayerHead.rotation.z,0.0,delta*4)
		#if Input.is_action_just_pressed("wpn1") or Input.is_action_just_pressed("wpn2"):
		#	PlayerHead.rotation.z = lerp(PlayerHead.rotation.z,PlayerHead.rotation.z+(randf_range(-1,1)),delta*1)
	
func reset_shoot(delta):
	shoot_delay_timer -= delta
	if shoot_delay_timer <= 0:
		ready_to_shoot = true
		
		shoot_delay_timer = SHOOT_DELAY
		
# Updates camera movement
func _update_movement(delta):
	#UI.debug_gui.text = "X: %.2f\nY: %.2f\nZ: %.2f" % [position.x,position.y,position.z]
	# Computes desired direction from key states
	_direction = Vector3(
		(_d as float) - (_a as float), 
		(_e as float) - (_q as float),
		(_s as float) - (_w as float)
	)
	
	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Compute modifiers' speed multiplier
	var speed_multi = 1
	if _shift: speed_multi *= SHIFT_MULTIPLIER
	#if _alt: speed_multi *= ALT_MULTIPLIER
	
	# Checks if we should bother translating the camera
	if _direction == Vector3.ZERO and offset.length_squared() > _velocity.length_squared():
		# Sets the velocity to 0 to prevent jittering due to imperfect deceleration
		_velocity = Vector3.ZERO
	else:
		# Clamps speed to stay within maximum value (_vel_multiplier)
		_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
		_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
		_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	
		translate(_velocity * delta * speed_multi)
		#GameManager.effect_cam.translate(_velocity * delta * speed_multi)

func ChangeFov(f):
	PlayerCamera.fov = f
	#GameManager.effect_cam.fov = f

func ChangePosition(pos : Vector3):
	self.position = pos
	
func ChangeRotation(rot : Vector3):
	self.rotation_degrees = rot

func ChangeRotationCutScene(rot : Vector3):
	rotation.y = rot.y
	PlayerCamera.rotation.x = rot.x
	PlayerCamera.rotation.z = rot.z
	
func _ready():
	#await get_tree().create_timer(0.2).timeout
	if not GameManager.pause:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#GameManager.effect_cam.position = position
	#GameManager.effect_cam.rotation = rotation
	

# Damage of player
func Hit(value : float,by=null):
	GameManager.PlaySFXLoaded("hit_sound")
	
	#vibration
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(300)
		
	if not GameManager.godmode:
		health -= value
	#GameManager.Gui.ShowMessage(("-%.2f" % value)+"%")
	#print("AI at screen pos: %s" % str(PlayerCamera.unproject_position(by.position)))
	if by != null:
		#print("Unproject position: X -> %.2f, Y - > %.2f" % [PlayerCamera.unproject_position(by.position)[0],PlayerCamera.unproject_position(by.position)[1]])
		# hit camera effect
		shoot_cam_anim(true,randf_range(-2,4),0,randf_range(-2,4))
		if not PlayerCamera.is_position_behind(by.global_transform.origin):
			# if attack from left
			if PlayerCamera.unproject_position(by.position)[0] < get_viewport().size.x/2:
				GameManager.Gui.damage_l.show()
			# if attack from right
			if PlayerCamera.unproject_position(by.position)[0] > get_viewport().size.x/2:
				GameManager.Gui.damage_r.show()
			# if attack from center
			if PlayerCamera.unproject_position(by.position)[0] > get_viewport().size.x/2-128 and \
			PlayerCamera.unproject_position(by.position)[0] < get_viewport().size.x/2+128:
				GameManager.Gui.damage_l.show()
				GameManager.Gui.damage_r.show()
		else:
			GameManager.Gui.damage_l.show()
			GameManager.Gui.damage_r.show()
		# if enemies behind the player or out of screen
		#print(PlayerCamera.unproject_position(by.position)[0])
		#if PlayerCamera.unproject_position(by.position)[0] > DisplayServer.screen_get_size(0).x or \
		#PlayerCamera.unproject_position(by.position)[0] < 0:
		#	GameManager.Gui.damage_l.show()
		#	GameManager.Gui.damage_r.show()
			
	_update_health_visual()
	
	if not is_dead and health <= 0:
		health = 0
		is_dead = true
		GameManager.pause = true
		if GameManager.current_level != null:
			GameManager.current_level.queue_free()
			GameManager.current_level = null
		GameManager.Gui.death_screen.show()
		GameManager.WipePlayerData()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		dead.emit()
	await get_tree().create_timer(0.5).timeout
	GameManager.Gui.damage_l.hide()
	GameManager.Gui.damage_r.hide()
	
func Death():
	if not is_dead and health >= 0:
		health = 1
		is_dead = true
		GameManager.pause = true
		if GameManager.current_level != null:
			GameManager.current_level.queue_free()
			GameManager.current_level = null
		GameManager.Gui.death_screen.show()
		GameManager.WipePlayerData()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.Gui.damage_l.hide()
		GameManager.Gui.damage_r.hide()
	
func Heal(value : float):
	if health < health_max:
		health += value
	if health > health_max:
		health = health_max
	_update_health_visual()
	
func SetMaxHp(value : float):
	health_max = value
	_update_health_visual()
	
func AddMaxHp(value : float):
	health_max += value
	_update_health_visual()

func LowMaxHp(value : float):
	health_max -= value
	if health > health_max:
		SetHealth(health_max)
	_update_health_visual()

func SetHealth(value : float):
	health = value
	_update_health_visual()
	
func _update_health_visual():
	var hp_bar_gui = GameManager.Gui.health_bar
	var hp_bar_inv = GameManager.Gui.health_bar_inv
	
	hp_bar_gui.max_value = health_max
	hp_bar_gui.value = health
	hp_bar_inv.max_value = health_max
	hp_bar_inv.value = health
	
func _update_rad_visual():
	var rad_bar = GameManager.Gui.rad_bar
	rad_bar.value = int(antirad_timer)

func shoot_cam_anim(just_anim: bool = false,x=randf_range(1, 2),y=randf_range(0.5, 1),z=randf_range(0.5, 2)):
	is_recoiling = true
	recoil_timer = 0.0
	last_recoil_dir = 1.0 if randf() < 0.5 else -1.0
	
	var force_rot_x = x
	var force_rot_y = y
	var force_rot_z = z
	
	recoil_force_pos = Vector3(randf_range(0.5, 3), randf_range(0.8, 2.5), randf_range(2.5, 8.5))
	recoil_force_rot = Vector3(force_rot_x, force_rot_y, force_rot_z)
	
	if not just_anim:
		ready_to_shoot = false

func recoil(delta: float) -> void:
	if is_recoiling:
		recoil_timer += delta * 3
		
		var recoil_pos_offset = Vector3.ZERO
		if use_recoil_pos_x:
			recoil_pos_offset.x = recoil_pos_curves[0].sample(recoil_timer) * recoil_force_pos.x * last_recoil_dir
		if use_recoil_pos_y:
			recoil_pos_offset.y = recoil_pos_curves[1].sample(recoil_timer) * recoil_force_pos.y
		if use_recoil_pos_z:
			recoil_pos_offset.z = recoil_pos_curves[2].sample(recoil_timer) * recoil_force_pos.z

		recoil_pos_offset *= delta
		
		recoil_pos_offset = Vector3(
			clampf(recoil_pos_offset.x, recoil_min, recoil_max),
			clampf(recoil_pos_offset.y, recoil_min, recoil_max),
			clampf(recoil_pos_offset.z, recoil_min, recoil_max)
		)

		#fps_hands.translate_object_local(recoil_pos_offset)
		
		var recoil_rot_offset = Vector3.ZERO
		if use_recoil_rot_x:
			recoil_rot_offset.x = recoil_rot_curves[0].sample(recoil_timer) * recoil_force_rot.x
		if use_recoil_rot_y:
			recoil_rot_offset.y = recoil_rot_curves[1].sample(recoil_timer) * recoil_force_rot.y * last_recoil_dir
		if use_recoil_rot_z:
			recoil_rot_offset.z = recoil_rot_curves[2].sample(recoil_timer) * recoil_force_rot.z * last_recoil_dir

		recoil_rot_offset *= delta

		#fps_hands.rotate_object_local(Vector3(1, 0, 0), recoil_rot_offset.x)
		#fps_hands.rotate_object_local(Vector3(0, 1, 0), recoil_rot_offset.y)
		#fps_hands.rotate_object_local(Vector3(0, 0, 1), recoil_rot_offset.z)
		
		PlayerHead.rotate_x(recoil_rot_offset.x-recoil_rot_offset.x/2)
		PlayerHead.rotate_y(recoil_rot_offset.y-recoil_rot_offset.y/2)
		PlayerHead.rotate_z(recoil_rot_offset.z-recoil_rot_offset.z/2)
		#hud.position.y = -(-recoil_pos_offset.y*2)	
		#GameManager.effect_cam_head.rotate_object_local(Vector3(1, 0, 0), recoil_rot_offset.x-recoil_rot_offset.x/2)
		#GameManager.effect_cam_head.rotate_object_local(Vector3(0, 1, 0), recoil_rot_offset.y-recoil_rot_offset.y/2)
		#GameManager.effect_cam_head.rotate_object_local(Vector3(0, 0, 1), -recoil_rot_offset.z-recoil_rot_offset.z/2)
		
		#shoot_ray.rotate_object_local(Vector3(1, 0, 0), recoil_rot_offset.x*0.2)
		#shoot_ray.rotate_object_local(Vector3(0, 1, 0), recoil_rot_offset.y*0.2)
		#shoot_ray.rotate_object_local(Vector3(0, 0, 1), recoil_rot_offset.z*0.2)
		
		if recoil_timer >= 1.0:
			is_recoiling = false
			recoil_timer = 0.0

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "wpn_draw":
		pass
		#hud_anim_player.stop()
		#hud_anim_player.play("wpn_idle")
		#hud.set_deferred("position",GameManager.weapon_system.current_weapon.hud_pos)
		
		#print("+ Анімація [%s] була завершена" % anim_name)
		#GameManager.weapon_system.can_shoot = true
	if anim_name == "reload" or anim_name == "reload_2":
		PlayAudio(audio,"assets/sounds/reload_sound.wav")
		GameManager.weapon_system.call_deferred("ReloadWeapon")
		#await get_tree().create_timer(0.1).timeout
		GameManager.weapon_system.UpdateAmmo()
	hud_anim_player.play("wpn_idle")


func _on_trigger_body_area_entered(area):
	if area is EYEZONE:
		emit_signal("in_eyezone", area)
		#GameManager.Gui.ShowMessage("Player entered in %s eyezone!" % area.name)
		current_eyezone = area
		area.player = self
		
	else:
		var rad_icn_anim : AnimationPlayer = GameManager.Gui.rad_icon.get_node("pda_anim") as AnimationPlayer		
		# RADIATION ZONE
		radiation = true
		GameManager.Gui.rad_icon.show()
		rad_icn_anim.play("blink")
	GameManager.GameProcess.on_area3d_entered(area,self)

func _on_trigger_body_area_exited(area):
	# IN EYEZONE (COMBAT ZONE)
	if area is EYEZONE:
		emit_signal("out_from_eyezone", area)
		current_eyezone = null
		area.player = null
	else:
		# IN RADIATION ZONE
		var rad_icn_anim : AnimationPlayer = GameManager.Gui.rad_icon.get_node("pda_anim") as AnimationPlayer
		radiation = false
		GameManager.Gui.rad_icon.hide()
		rad_icn_anim.stop()
		radiation_timer = 5.0
	GameManager.GameProcess.on_area3d_exited(area,self)


func _on_ready():
	game_init()
