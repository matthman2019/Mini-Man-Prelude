class_name Collectible extends Sprite2D

@export var collectibleType := Global.Collectibles.BOOST

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture = Globals.CollectibleTextures[collectibleType]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	var minifigureParent = body
	while minifigureParent != get_tree().root and minifigureParent is not Minifigure:
		print(minifigureParent)
		minifigureParent = minifigureParent.get_parent()
	if minifigureParent is not Minifigure:
		print("Not a minifigure!")
		return

	minifigureParent.obtainCollectible.emit(collectibleType)
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	while not get_tree().paused: # this works, annoyingly enough
		await get_tree().process_frame
	while get_tree().paused:
		await get_tree().process_frame
	visible = false
