extends CanvasLayer

@onready var text := $Control/PanelContainer/RichTextLabel
@onready var container := $Control/PanelContainer
@onready var fanfare := $Fanfare

var hidden = Vector2(1920, 0)
var showing = Vector2(1920, 100)

func _ready() -> void:
	visible = false
	container.size = hidden
	#await get_tree().create_timer(5).timeout
	#activate("Hello there! Press X to run.")

func showText(collectibleName: String):
	text.text = collectibleName
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(container, "size", showing, .5)
	await tween.finished

func hideText():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(container, "size", hidden, .5)
	await tween.finished

func activate(collectibleName: String):
	get_tree().paused = true
	visible = true
	fanfare.play()
	showText(collectibleName)
	await fanfare.finished
	get_tree().paused = false
	await hideText()
	visible = false
	
