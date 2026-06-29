extends PanelContainer

signal dialogButtonPressed(name: String)

var bracketMode: bool = false
var pauseDuration: float = 0.5
var shortPauseDuration: float = 0.2
var textDispId: int = 0

@onready var textbox = $HBoxContainer/MarginContainer2/VBoxContainer/RichTextLabel
@onready var imagebox = $HBoxContainer/MarginContainer/TextureRect
@onready var buttonContainer = $HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer
@onready var dialogButton = Button.new()
'''
@onready var deo = preload("res://assets/icons/Deo.jpg")
@onready var clunk = preload("res://assets/icons/Clunk.png")
@onready var nathan = preload("res://assets/icons/Nathan.jpg")
@onready var boi = preload("res://assets/icons/Boi3.png")
'''
signal keyPressed
signal keyReleased
var spaceDown: bool = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.as_text() == "Space":
		if event.is_pressed():
			keyPressed.emit()
			spaceDown = true
		else:
			keyReleased.emit()
			spaceDown = false

func _displayTextWithKey(text: String, instantText: bool = false):
	await _dispText(text, instantText)
	await keyPressed
	await keyReleased

func _dispText(dispText: String, instantText: bool = false):
	visible = true
	textDispId += 1
	var localTextDispId = textDispId
	if instantText:
		textbox.text = dispText
		return

	textbox.text = ""
	var index = 0
	while index < len(dispText):
		var character = dispText[index]
		if character == "[":
			bracketMode = true
		if character == "⏸":
			await get_tree().create_timer(pauseDuration).timeout
			continue
		if (not bracketMode) and (not spaceDown):
			await get_tree().process_frame
		if spaceDown:
			if index % 3 == 0:
				await get_tree().process_frame
		if character == "]":
			bracketMode = false

		# textDispId is to stop dialog if new dialog is shown (to prevent 2 dialog being mingled at once)
		if textDispId != localTextDispId:
			break
		textbox.text += character
		

		if character == ",":
			await get_tree().create_timer(shortPauseDuration).timeout
		index += 1

	bracketMode = false

func _switchImage(image: Texture2D):
	imagebox.texture = image

## Displays dialog.
func dialog(image: Texture2D, text: String):
	_clearDialogButtons()
	_switchImage(image)
	visible = true
	await _displayTextWithKey(text, false)
	visible = false

func _clearDialogButtons():
	for child in buttonContainer.get_children():
		child.queue_free()

func _buttonPressedCallback(buttonName: String):
	dialogButtonPressed.emit(buttonName)

func _addDialogButton(text: String):
	var returnButton := Button.new()
	returnButton.text = text
	returnButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	returnButton.pressed.connect(_buttonPressedCallback.bind(text))
	buttonContainer.add_child(returnButton)

func choice(image: Texture2D, text: String, choices: Array) -> String:
	# show dialog
	_clearDialogButtons()
	_switchImage(image)
	visible = true
	await _dispText(text)
	
	# show choices
	for choiceText in choices:
		assert(choiceText is String)
		_addDialogButton(choiceText)
	
	var result = await dialogButtonPressed
	visible = false
	return result

func _ready():
	'''
	await dialog(boi, "Hi, I'm Boi!")
	await dialog(clunk, "And I'm Clunk!")
	await dialog(boi, "We're the robots that will help you play this game!")
	await dialog(deo, "I am your creator")
	await dialog(boi, "Nice try, we only hail lord David")
	await dialog(clunk, "Or Sam")
	await dialog(deo, "I am unsure how to respond, so I will use ChatGPT:")
	await dialog(deo, "The quiet resilience of moss is one of nature’s most overlooked marvels, thriving in places where other plants struggle and transforming forgotten corners into soft, green tapestries. Unlike towering trees or vibrant flowers that demand attention, moss grows patiently and persistently, spreading across stones, tree trunks, and damp soil with a kind of understated determination. It doesn’t rely on deep roots or elaborate structures; instead, it absorbs moisture directly through its leaves, making it remarkably adaptable in environments ranging from dense forests to urban sidewalks. This simplicity is deceptive, however, because moss plays a crucial ecological role—retaining water, preventing soil erosion, and even helping to create new soil over time by breaking down rock surfaces. In many ways, moss embodies a slower, quieter rhythm of life, one that contrasts sharply with the fast-paced world humans have constructed. It invites a closer look, rewarding those who pause long enough to notice the intricate patterns and textures that form miniature landscapes beneath their feet. Perhaps there’s something to learn from moss: a reminder that growth doesn’t always have to be loud or visible to be meaningful, and that persistence, even in the smallest forms, can leave a lasting impact on the world.")
	'''
	if get_parent() == get_tree().current_scene:
		print("I am the root node")
		#print(await choice(deo, "Am I locked in?", ["Yes", "No", "I'm not sure", "I don't care"]))
	else:
		visible = false
