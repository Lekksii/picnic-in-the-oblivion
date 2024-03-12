extends Node
class_name AmbientSystem

## Ambient system that allows us to play background music on levels to add more game feel

@onready var main_ambient_music : AudioStreamPlayer = $ambient
@onready var bus_ambient = AudioServer.get_bus_index("AMBIENT")
@onready var bus_ambient_sfx = AudioServer.get_bus_index("AMBIENT_SFX")
var _bus_sfx_volume : float = -80
var _bus_amb_volume : float = -80
var ambient_json
var ambient_random = false
var _ambient_random_timer = 0.0
var _ambient_random_delay = 0.0
var _ambient_random_list = []
var _ambient_track_name = ""
var _ambient_current_sfx = null
var _ambient_random_delay_list = []
var ambient_backgrounds : Array[AudioStreamPlayer]= []

## Emits every time when player loaded on level and gets it's ID
signal player_on_level

## Function uses when need to disable all ambient system when loading to MainMenu
func MainMenuAmbientOff():
	# if ambient music is playing - stop it
	main_ambient_music.stop()
	# stop timer for random ambient sfx
	ambient_random = false
	# set ambient track name to none
	_ambient_track_name = ""
	# clear random sfx list of sounds
	_ambient_random_list.clear()
	# clear delay time of random sfx sounds
	_ambient_random_delay_list.clear()
	
	# if we have still playing random sfx - stop it and delete
	if _ambient_current_sfx != null:
		_ambient_current_sfx.queue_free()
		_ambient_current_sfx = null
	
	# if we have still playing background ambients playing - delete it
	if ambient_backgrounds.size() > 0:
		for amb in ambient_backgrounds:
			amb.queue_free()
			
	# clear list after freed	
	ambient_backgrounds.clear()

## Play ambient music.
## path - string path, ex: "assets/sounds/*.wav" 
## volume - float for db of stream
func PlayAmbientMusic(path: String,volume: float =-25.0):
	var audio_loader = AudioLoader.new()
	main_ambient_music.set_stream(audio_loader.loadfile(GameManager.app_dir+path,true))
	main_ambient_music.volume_db = volume
	main_ambient_music.play()

## Play background ambient music (can be used as layered music)
func PlayAmbientBackground(path: String,volume: float=0.0):
	var audio_loader = AudioLoader.new()
	var new_bg = main_ambient_music.duplicate()
	new_bg.volume_db = volume
	new_bg.set_stream(audio_loader.loadfile(GameManager.app_dir+path,true))
	add_child(new_bg)
	new_bg.name = main_ambient_music.name
	new_bg.play()
	ambient_backgrounds.append(new_bg)
	
## Play ambient sound sfx once and delete it when finished, good for random sounds like wind, birds etc.
func PlayAmbientSFXOnce(path: String):
	var audio_loader = AudioLoader.new()
	var ref_stream : AudioStreamPlayer = $amb_sfx0
	
	var new_audio : AudioStreamPlayer = ref_stream.duplicate() as AudioStreamPlayer
	new_audio.finished.connect(new_audio.queue_free)
	new_audio.set_stream(audio_loader.loadfile(GameManager.app_dir+path))
	add_child(new_audio)
	new_audio.name = ref_stream.name
	new_audio.play()
	_ambient_current_sfx = new_audio

func _ready():
	ambient_json = Utility.read_json("assets/gameplay/ambient_manager.json")
	player_on_level.connect(init_ambient)

## Function that connected to 'player_on_level' signal and will run when signal will be emited.	
func init_ambient(level_id):
	ambient_random = false
	if _ambient_random_list.size() > 0:
		_ambient_random_list.clear()
		
	if ambient_backgrounds.size() > 0:
		for amb in ambient_backgrounds:
			amb.queue_free()
			
	ambient_backgrounds.clear()
	
	#print("Player inited ambient on level -> %s" % level_id)
	if ambient_json:
		for amb_level in ambient_json:
			if typeof(amb_level["level_id"]) == TYPE_STRING and amb_level["level_id"] == level_id or \
			   typeof(amb_level["level_id"]) == TYPE_ARRAY and amb_level["level_id"].has(level_id):
				if _ambient_current_sfx != null:
					_ambient_current_sfx.queue_free()
					_ambient_current_sfx = null
					AudioServer.set_bus_volume_db(bus_ambient_sfx,-80.0)
					_bus_sfx_volume = -80.0
				
				if "random_sfx" in amb_level:
					_ambient_random_list = amb_level["random_sfx"].duplicate()
				
				# if ambient track not the same - apply name and play new track
				if _ambient_track_name != amb_level["ambient"]:
					_ambient_track_name = amb_level["ambient"]
					PlayAmbientMusic("assets/sounds/"+amb_level["ambient"],amb_level["ambient_volume"])
				
				AudioServer.set_bus_volume_db(bus_ambient,-80.0)
				_bus_amb_volume = -80.0
				
				if "background_ambients" in amb_level:
					if _ambient_current_sfx != null:
						_ambient_current_sfx.queue_free()
						_ambient_current_sfx = null
					
					for amb_bg in amb_level["background_ambients"]:
						PlayAmbientBackground("assets/sounds/"+amb_bg,amb_level["ambient_bg_volume"] if "background_ambients_volumes" not in amb_level else amb_level["background_ambients_volumes"][amb_level["background_ambients"].find(amb_bg)])
				
				if "random_sfx" in amb_level:
					if "random_sfx_delay" in amb_level:
						_ambient_random_delay = randf_range(amb_level["random_sfx_delay"][0],amb_level["random_sfx_delay"][1])
						_ambient_random_timer = _ambient_random_delay
					_ambient_random_delay_list = amb_level["random_sfx_delay"].duplicate()
					ambient_random = true
				break
			else:
				MainMenuAmbientOff()

func _process(delta):
	# If ambient SFX BUS volume is not standard - make fade in and set volume
	if _bus_sfx_volume <= -31.0:
		_bus_sfx_volume += linear_to_db(4)
		AudioServer.set_bus_volume_db(bus_ambient_sfx,_bus_sfx_volume)
		return
		#print("AMB SFX DB: %.2f" % _bus_sfx_volume)
	# If ambient BUS volume is not standard - make fade in and set volume
	if _bus_amb_volume <= -16.5:
		_bus_amb_volume += linear_to_db(4)
		AudioServer.set_bus_volume_db(bus_ambient,_bus_amb_volume)
		return
		#print("AMB DB: %.2f" % _bus_amb_volume)
	# Timer for random sfx sounds
	if ambient_random:
		if _ambient_current_sfx == null:
			_ambient_random_timer -= delta * 1
		if _ambient_random_timer <= 0:
			if _ambient_random_list.size() > 0:
				PlayAmbientSFXOnce("assets/sounds/"+_ambient_random_list.pick_random())
			_ambient_random_delay = randf_range(_ambient_random_delay_list[0],_ambient_random_delay_list[1])
			_ambient_random_timer = _ambient_random_delay
		return
