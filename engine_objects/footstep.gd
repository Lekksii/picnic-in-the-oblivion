extends AudioStreamPlayer

func _on_finished():
	self.queue_free()
