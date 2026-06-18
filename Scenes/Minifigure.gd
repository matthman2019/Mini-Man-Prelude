@tool
class_name Minifigure extends CharacterBody2D


@export var trigger_redraw : bool = false:
	set(value):
		queue_redraw()
@export var fists : bool = false

@onready var SFX = $"../SFX"

signal obtainCollectible

var acceleration : Vector2 = Vector2.ZERO
var frictionConstant: float = 0.9
var walkSpeed: float = 15
var maxWalkSpeed: float = 75
var maxRunSpeed: float = 1000
var jumpPower: float = 1000 # put in a positive value; the function jump() makes it negative
var gravityPower: float = 50

var onGround: bool = true
var walking: bool = true
var walkDirection: int = 0 # -1 is left, 1 is right, 0 is neither
var skidStopping: bool = false
var running: bool = true
var runJumping: bool = false
var runJumpSpeedThreshold: int = 200

var watchEnabled: bool = true


@export var inspector_velocity: Vector2 = Vector2.ZERO:
	set(value):
		velocity = inspector_velocity
		inspector_velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	obtainCollectible.connect(getCollectible)

## applies acceleration to velocity.
func apply_vectors(_delta: float):
	velocity += acceleration
	# move_and_slide does the rest

## Apply friction (passive or active)
func friction(constant: float):
	# slowing down friction
	if onGround and not walking:
		velocity.x *= constant
		
	# actively stopping friction (works in air too)
	skidStopping = false
	if (walkDirection == 1 and velocity.x < 0) or (walkDirection == -1 and velocity.x > 0):
		velocity.x *= constant
		skidStopping = true

## Resets acceleration to 0.
func reset_acceleration():
	acceleration = Vector2.ZERO

## Applies gravity to acceleration.
func gravity():
	acceleration += Vector2(0, gravityPower)

## Jump! Also handles onGround logic.
func jump():
	if onGround:
		velocity.y = -jumpPower
		onGround = false
		# running jump
		if running and abs(velocity.x) > runJumpSpeedThreshold:
			runJumping = true
			velocity.y -= abs(velocity.x) / 9

## Reset onGround to true.
func backOnGround():
	onGround = true
	runJumping = false

## clamps velocity to given value, both positive and negative.
func clamp_velocity(value: float, damp: float = 0.9):
	if velocity.x > value:
		velocity.x *= damp
	elif velocity.x < -value:
		velocity.x *= damp

## Process inputs on the x axis to walk.
func process_walk(input_x: float):
	if abs(input_x) > 0.1:
		velocity.x += input_x
		walking = true
		if input_x > 0:
			walkDirection = 1
		else:
			walkDirection = -1
	else:
		walking = false
		walkDirection = 0
	# operations if walking
	if walking:
		if input_x > 0:
			scale = Vector2(1, 1)
			rotation_degrees = 0
		else:
			scale = Vector2(1, -1)
			rotation_degrees = 180

@onready var boostProgressBar = $"../UI/Control/BoostReloadBar"
var boosting: bool = false
var boostAnimFreeze = false
var boostRecharge: float = 2.0
var obtainedBoost: bool = false # when saving is made, this will need to be changed
func apply_boost():
	if not running:
		return
	if boosting:
		return
	boosting = true
	if walkDirection == 1:
		velocity.x += 3000
	elif walkDirection == -1:
		velocity.x -= 3000
	else:
		boosting = false
		return
	boostProgressBar.showReload(boostRecharge)
	startBoostAnimFreeze()
	playBoostSoundEffect()
	await get_tree().create_timer(boostRecharge).timeout
	boosting = false
func startBoostAnimFreeze():
	if boostAnimFreeze:
		return
	boostAnimFreeze = true
	await get_tree().create_timer(0.3).timeout
	boostAnimFreeze = false
@onready var boostSounds = [
	preload("res://Assets/Audio/sfx/whoosh-sfx.wav"),
	preload("res://Assets/Audio/sfx/simple-whoosh.wav"),
]
func playBoostSoundEffect():
	SFX.playSoundEffect(boostSounds.pick_random())

@onready var collectibleAquisition := $"../CollectibleAquisition"
func getCollectible(collectibleName: Globals.Collectibles):
	var c = Globals.Collectibles
	match collectibleName:
		c.BOOST:
			obtainedBoost = true
		_:
			return
	collectibleAquisition.activate(Globals.CollectibleNameOnAquisition[collectibleName])

## Process inputs into walking or jumping.
func process_inputs():
	var input_dir := Input.get_vector("left", "right", "up", "down") * walkSpeed
	process_walk(input_dir.x)
	running = Input.is_action_pressed("run")
	if running:
		clamp_velocity(maxRunSpeed)
	else:
		clamp_velocity(maxWalkSpeed)
	if input_dir.y < 0:
		jump()
	
	# boost (might not be in final game)
	if obtainedBoost and Input.is_action_just_pressed("boost"):
		apply_boost()
	
	# watch switch
	if Input.is_action_just_pressed("watch switch"):
		watchEnabled = not watchEnabled

@onready var animationPlayer = $AnimationPlayer
func process_animations():
	# maybe use an animation tree eventually
	var speed = 1
	var anim = "idle"
	if not onGround:
		if runJumping:
			anim = "running jump"
		elif velocity.y < 0:
			anim = "jump up"
		else:
			anim = "fall down"
	elif abs(velocity.x) > 46:
		if skidStopping and running:
			anim = "skid"
		elif running:
			anim = "run"
			if boostAnimFreeze:
				speed = 0
			else:
				speed = clamp(abs(velocity.x) / 500, 1, 20)
		elif walking:
			anim = "walk"
		else:
			anim = "idle"
	else:
		anim = "idle"
	animationPlayer.play(anim)
	animationPlayer.speed_scale = speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	process_animations()

# thanks gemini!
func isValueInRange(value: float, center: float, margin: float) -> bool:
	var min_val = center - margin
	var max_val = center + margin
	return value >= min_val and value <= max_val

const HALFPI = PI/2
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	reset_acceleration()
	process_inputs()
	friction(frictionConstant)
	gravity()
	apply_vectors(delta)
	#var stored_velocity: Vector2 = velocity
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		# var collider = collision.get_collider()
		
		# if we're standing on ground and the angle is one we can stand on, go back on ground
		var tileRID = collision.get_collider_rid()
		var layer = PhysicsServer2D.body_get_collision_layer(tileRID)
		var normalAngle = collision.get_normal().angle() * -1
		if layer == 1 and isValueInRange(normalAngle, HALFPI, floor_max_angle):
			backOnGround()

@onready var skeleton = $Skeleton2D
func _draw() -> void:
	# recursively draw limbs
	var draw_lines_to_children = func(
		parentBone: Bone2D, 
		startingPos: Vector2, 
		startingRotation: float, 
		self_ref: Callable
		):
		for child in parentBone.get_children():
			if not child is Bone2D:
				continue
			assert(child is Bone2D)
			var nextRotation = parentBone.rotation + startingRotation
			var nextPos = startingPos + child.position.rotated(nextRotation)
			
			if boostAnimFreeze: # boost aura glow
				draw_line(startingPos, nextPos, Color.YELLOW, 20, true)
				draw_circle(nextPos, 10, Color.YELLOW)

			draw_line(startingPos, nextPos, Color.BLACK, 10, true)
			draw_circle(nextPos, 5, Color.BLACK)
			self_ref.call(child, nextPos, nextRotation, self_ref)
		# head
		if parentBone.name == "Neck":
			if boostAnimFreeze:
				draw_circle(startingPos, 25, Color.YELLOW)
			draw_circle(startingPos, 20, Color.BLACK, true, -1.0, true)
		# fists
		elif (parentBone.name == "LForearm" or parentBone.name == "RForearm") and fists:
			draw_circle(startingPos, 9, Color.BLACK, true, -1.0, true)
		elif watchEnabled and (parentBone.name == "LForearm"): # watch
			draw_circle(startingPos - Vector2(-5, 20).rotated(startingRotation + parentBone.rotation), 8, Color.BLUE)
	var hip = $Skeleton2D/Hip
	draw_lines_to_children.call(hip, hip.position, 0, draw_lines_to_children)
	
	#draw_circle(Vector2.ZERO, 20.0, Color.BLACK)
	#draw_line(Vector2.ZERO, Vector2(0, 100), Color.BLACK, 10, true)
