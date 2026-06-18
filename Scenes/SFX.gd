extends Node2D

@onready var childSFX = $SFX
func playSoundEffect(effect: AudioStream):
	var newSFX : AudioStreamPlayer = childSFX.duplicate()
	add_child(newSFX)
	newSFX.stream = effect
	newSFX.play()
	newSFX.finished.connect(newSFX.queue_free)
