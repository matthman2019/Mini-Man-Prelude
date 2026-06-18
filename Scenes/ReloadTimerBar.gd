class_name ReloadBar extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	step = 0.001
	set_process(false)


'''
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value += delta
	print(value, " ", max_value)
	if value >= max_value:
		visible = false
		set_process(false)
'''

func _process(delta: float) -> void:
	value += delta 
	#print("Value: ", value, " | Delta: ", delta)
	if value >= max_value:
		visible = false
		set_process(false)

func showReload(time: float):
	visible = true
	max_value = time
	value = 0
	set_process(true)
