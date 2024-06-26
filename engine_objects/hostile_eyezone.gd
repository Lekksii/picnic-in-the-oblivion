extends Area3D
class_name EYEZONE

@export var id : String = ""
var enemies = []
var player

func _ready():
	if GameManager.ai_ignore: return
	#if not GameManager.player.can_look: return
	#if GameManager.pause: return 
	for enemy in enemies:
		enemy.can_attack = false
	
	await get_tree().create_timer(0.1).timeout
	# randomly pick enemy and allow him permission to attack player
	if enemies.size() > 0:
		var ai = enemies.pick_random()
		ai.delay_timer = 2.0
		ai.can_attack = true
	
