extends OmniLight3D

@export var noise : NoiseTexture2D
var time_passed : float
@export_range(1,10) var flicker_speed : float = 1
@export var flicker: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flicker:
		time_passed += delta * flicker_speed
		var sampled_noise = noise.noise.get_noise_1d(time_passed)
		sampled_noise = abs(sampled_noise)
		
		light_energy = sampled_noise
