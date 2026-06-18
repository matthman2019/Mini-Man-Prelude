extends AudioStreamPlayer
# I took this script from an old project

var audio_dict = {}
var audio_folder_string = "res://Assets/Audio"
@onready var audio_folder = DirAccess.open(audio_folder_string)

@onready var fade_duration:float = 2.0

var current_song_type_playing = null

@export var defaultMusicCategory : String = "The Zone"
@export var autoPlay : bool = true

func _ready() -> void:
	var music_categories = audio_folder.get_directories()
	for category in music_categories:
		audio_dict[category] = []
		var category_dir_string = audio_folder_string.path_join(category)
		var category_dir = DirAccess.open(category_dir_string)
		for file in category_dir.get_files():
			if not file.ends_with(".import"):
				continue
			audio_dict[category].append(category_dir_string.path_join(file.get_basename()))
	
	finished.connect(change_song_instant)
	
	if autoPlay:
		change_song_instant()

func fadeOut():
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "volume_db", -80, fade_duration)
	fade_out_tween.play()
	await fade_out_tween.finished
	self.stop()
	
func change_song_with_fade(song_type : String = defaultMusicCategory):
	if song_type == current_song_type_playing:
		return
	
	# fade out
	await fadeOut()
	
	# load new song
	var songs_of_type:Array = audio_dict[song_type]
	# gets a new random song
	var song_path = songs_of_type.pick_random()
	# loads it in
	self.stream = load(song_path)
	current_song_type_playing = song_type
	self.play()
	
	# fade back in
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(self, "volume_db", 0, fade_duration)
	fade_in_tween.play()

func change_song_to_with_fade(song):
	if not song:
		change_song_with_fade()
		return
	
	# fade out
	await fadeOut()
	
	# loads it in
	self.stream = song
	current_song_type_playing = "custom"
	self.play()
	
	# fade back in
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(self, "volume_db", 0, fade_duration)
	fade_in_tween.play()
	
func change_song_instant():
	
	# first figure out song type
	var song_type = defaultMusicCategory
	var songs_of_type:Array = audio_dict[song_type]
	# gets a new random song
	var song_path = songs_of_type.pick_random()
	# loads it in
	self.stream = load(song_path)
	self.play()
	
