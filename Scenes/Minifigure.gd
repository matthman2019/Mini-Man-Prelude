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
var wallholdMaxSpeed: float = 100

var onGround: bool = true
var walking: bool = true
var walkDirection: int = 0 # -1 is left, 1 is right, 0 is neither
var lastWalkDirection: int = 0
var canWalk: bool = true
var skidStopping: bool = false
var running: bool = true
var runJumping: bool = false
var runJumpSpeedThreshold: int = 200
var wallHolding: bool = false
var wallJumpFreeze: bool = false


var watchEnabled: bool = true
var auraColor: Color = Color.BLACK # black means no aura


@export var inspector_velocity: Vector2 = Vector2.ZERO:
	set(value):
		velocity = inspector_velocity
		inspector_velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	obtainCollectible.connect(_getCollectible)

## applies acceleration to velocity.
func _apply_vectors(_delta: float):
	velocity += acceleration
	# move_and_slide does the rest

## Apply friction (passive or active)
func _friction(constant: float):
	# slowing down friction
	if onGround and not walking:
		velocity.x *= constant
		
	# actively stopping friction (works in air too)
	skidStopping = false
	if (walkDirection == 1 and velocity.x < 0) or (walkDirection == -1 and velocity.x > 0):
		velocity.x *= constant
		skidStopping = true
	
	# wallhold friction
	if wallHolding:
		velocity.y = clamp(velocity.y, -1000, wallholdMaxSpeed)
	if wallJumpFreeze:
		velocity.x *= constant

## Resets acceleration to 0.
func _reset_acceleration():
	acceleration = Vector2.ZERO

## Applies gravity to acceleration.
func _gravity():
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
	
	elif wallHolding and velocity.y > 0:
		velocity.y = -jumpPower
		velocity.x = -3000 * lastWalkDirection
		_startWalljumpFreeze()

## Freezes inputs for a little bit after walljumping. Currently does nothing.
func _startWalljumpFreeze():
	# currently there's no need for this
	'''
	canWalk = false
	walking = false
	wallJumpFreeze = true
	walkDirection *= -1
	var tree = get_tree()
	#await tree.create_timer(0.1).timeout
	canWalk = true
	wallJumpFreeze = false
	'''
	return


## Reset onGround to true.
func _backOnGround():
	onGround = true
	runJumping = false
	

## clamps velocity to given value, both positive and negative.
func _clampVelocity(value: float, damp: float = 0.9):
	if velocity.x > value:
		velocity.x *= damp
	elif velocity.x < -value:
		velocity.x *= damp

## Process inputs on the x axis to walk.
func _processWalk(input_x: float):
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
	

@onready var boostProgressBar = $"../UI/Control/BoostReloadBar"
var boosting: bool = false
var boostAnimFreeze = false
var boostRecharge: float = 2.0
var hiJumpRecharge: float = 2.0
var obtainedBoost: bool = true # when saving is made, this will need to be changed
var obtainedHiJump: bool = true
## how long one has to hold for boost to become hi jump
var highJumpTime: float = .5
var boostHeld: float = 0
func _tallyBoostHoldTime(delta: float):
	if (not boosting) and (not Input.is_action_pressed("boost")):
		if boostHeld > 0: _applyBoost(boostHeld) # make sure this finishes running before boostheld is set to zero
		boostHeld = 0
	else:
		boostHeld += delta
		if boostHeld < highJumpTime:
			auraColor = Color.YELLOW
		else:
			auraColor = Color.GREEN
func _applyBoost(boostHoldDuration: float):
	if boosting:
		return
	boosting = true
	if boostHoldDuration < highJumpTime:
		if walkDirection == 1:
			velocity.x += 3000
		elif walkDirection == -1:
			velocity.x -= 3000
		boostProgressBar.showReload(boostRecharge)
		_startBoostAnimFreeze()
		_playBoostSoundEffect()
		await get_tree().create_timer(boostRecharge).timeout
		boosting = false
	else:
		velocity.y -= 1500
		
		boostProgressBar.showReload(hiJumpRecharge)
		_startHiJumpAura()
		_playBoostSoundEffect()
		await get_tree().create_timer(hiJumpRecharge).timeout
		boosting = false
		''' # shift tab this to boost in current direction
		if walkDirection:
			velocity += Vector2.from_angle(velocity.angle()) * 3000'''
	'''else:
		boosting = false
		return'''

	
func _startBoostAnimFreeze():
	if boostAnimFreeze:
		return
	boostAnimFreeze = true
	auraColor = Color.YELLOW
	await get_tree().create_timer(0.3).timeout
	boostAnimFreeze = false
	auraColor = Color.BLACK
func _startHiJumpAura():
	auraColor = Color.GREEN
	await get_tree().create_timer(0.3).timeout
	auraColor = Color.BLACK
@onready var boostSounds = [
	preload("res://Assets/Audio/sfx/whoosh-sfx.wav"),
	preload("res://Assets/Audio/sfx/simple-whoosh.wav"),
]
func _playBoostSoundEffect():
	SFX.playSoundEffect(boostSounds.pick_random())


@onready var collectibleAquisition := $"../CollectibleAquisition"
func _getCollectible(collectibleName: Globals.Collectibles):
	var c = Globals.Collectibles
	match collectibleName:
		c.BOOST:
			obtainedBoost = true
		c.HIJUMP:
			obtainedHiJump = true
		_:
			pass
	collectibleAquisition.activate(Globals.CollectibleNameOnAquisition[collectibleName])

## Process inputs into walking or jumping.
func _processInputs(delta: float):
	# watch switch
	if Input.is_action_just_pressed("watch switch"):
		watchEnabled = not watchEnabled
	
	## HEY! DON'T PUT NON-WALKING INPUTS UNDER THIS!!!
	if not canWalk: # if we can't walk, return, but still clamp our velocity.
		if running:
			_clampVelocity(maxRunSpeed)
		else:
			_clampVelocity(maxWalkSpeed)
		return
	
	var input_dir := Input.get_vector("left", "right", "up", "down") * walkSpeed
	_processWalk(input_dir.x)
	running = Input.is_action_pressed("run")
	if running:
		_clampVelocity(maxRunSpeed)
	else:
		_clampVelocity(maxWalkSpeed)
	if input_dir.y < 0:
		jump()
	
	# boost (might not be in final game)
	'''
	if Input.is_action_just_pressed("boost"):
		_applyBoost()
	'''
	_tallyBoostHoldTime(delta)
	
	

func _faceRight():
	scale = Vector2(1, 1)
	rotation_degrees = 0
func _faceLeft():
	scale = Vector2(1, -1)
	rotation_degrees = 180

@onready var animationPlayer = $AnimationPlayer
func _processAnimations():
	# maybe use an animation tree eventually
	var speed = 1
	var anim = "idle"
	
	# first, scale (direction)
	# operations if walking
	if walkDirection == 1:
		_faceRight()
		lastWalkDirection = 1
	elif walkDirection == -1:
		_faceLeft()
		lastWalkDirection = -1
	
	# animation handling
	if not onGround:
		if wallHolding:
			anim = "walljump hold"
			if lastWalkDirection == 1:
				_faceLeft()
			else:
				_faceRight()
			'''if lastWalkDirection == 1:
				_faceLeft()
				rotation_degrees = 180
			else:
				_faceRight()'''
				
		elif runJumping:
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
	_processAnimations()

# thanks gemini!
func _isValueInRange(value: float, center: float, margin: float) -> bool:
	var min_val = center - margin
	var max_val = center + margin
	return value >= min_val and value <= max_val

const HALFPI = PI/2
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	_reset_acceleration()
	_processInputs(delta)
	_friction(frictionConstant)
	_gravity()
	_apply_vectors(delta)
	#var stored_velocity: Vector2 = velocity
	move_and_slide()
	
	wallHolding = false # we assume we're not wallholding every frame
	onGround = false
	
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		# var collider = collision.get_collider()
		
		# if we're standing on ground and the angle is one we can stand on, go back on ground
		var tileRID = collision.get_collider_rid()
		var layer = PhysicsServer2D.body_get_collision_layer(tileRID)
		var normalAngle = collision.get_normal().angle() * -1
		
		if layer == 1 and _isValueInRange(normalAngle, HALFPI, floor_max_angle):
			_backOnGround() # go back on ground
		elif is_equal_approx(normalAngle, 0.0) or is_equal_approx(normalAngle, -PI):
			wallHolding = true

@onready var skeleton = $Skeleton2D
func _draw() -> void:
	var drawAura : bool = auraColor != Color.BLACK and not Engine.is_editor_hint()
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
			
			if drawAura:
				draw_line(startingPos, nextPos, auraColor, 20, true)
				draw_circle(nextPos, 10, auraColor)

			draw_line(startingPos, nextPos, Color.BLACK, 10, true)
			draw_circle(nextPos, 5, Color.BLACK)
			self_ref.call(child, nextPos, nextRotation, self_ref)
		# head
		if parentBone.name == "Neck":
			if drawAura:
				draw_circle(startingPos, 25, auraColor)
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
