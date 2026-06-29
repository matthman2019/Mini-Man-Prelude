class_name Global extends Node

enum Collectibles {
	BOOST,
	MAGRAIL,
	GRAPPLER,
	BOARD,
	HIJUMP,
	FIRESUIT,
	SPINSLASH,
	SLIDE,
	ZIP,
	GUN,
	CRASH,
	SMASH,
	SPARK
}

var CollectibleNames : Array[String] = [
	"Boost",
	"Mag Rail",
	"Grappler",
	"Board",
	"Hi Jump",
	"Fire Suit",
	"Spin Slash",
	"Slide",
	"Zip",
	"Gun",
	"Crash",
	"Smash",
	"Spark"
]

var CollectibleNameOnAquisition : Array[String] = [
	"Boost - while running, activate by pressing Z",
	"Mag Rail - Tell the developers to add this!",
	"Grappler - This item should be unobtainable. Please contact the developers!",
	"Board - Tell the developers to add this!",
	"Hi Jump - while standing still, activate by pressing Z",
	"Fire Suit - Tell the developers to add this!",
	"Spin Slash - Tell the developers to add this!",
	"Slide - Tell the developers to add this!",
	"Zip - Tell the developers to add this!",
	"Gun - This item should be unobtainable. Please contact the developers!",
	"Crash - Tell the developers to add this!",
	"Smash - Tell the developers to add this!",
	"Spark - This item should be unobtainable. Please contact the developers!"
]
const powerupBase = "res://Assets/Images/powerups/"
const _zip := preload("res://Assets/Images/powerups/zip.svg")
func _getTexture(_name: String) -> Texture2D:
	if not FileAccess.file_exists(powerupBase + _name):
		return _zip
	else:
		return load(powerupBase + _name)

@onready var CollectibleTextures : Array[Texture2D] = [
	_getTexture("speedBooster.svg"),
	_zip,
	_zip,
	_zip,
	_getTexture("hiJump.svg"),
	_getTexture("fireSuit.svg"),
	_getTexture("spinSlash.svg"),
	_zip,
	_zip,
	_getTexture("gun.svg"),
	_getTexture("crash.svg"),
	_getTexture("smash.svg"),
	_getTexture("spark.svg")
]
