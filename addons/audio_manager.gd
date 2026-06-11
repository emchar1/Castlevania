extends Node

# PROPERTIES

var players: Dictionary[int, Array] = {}
var music_timer: Timer
var current_music := AudioData.Music.NONE


# FUNCTIONS

func _ready() -> void:
	prime_audio()


# Plays audio for sound (int) at volume, position, and (optional) pitch.
func play(
	sound: AudioData.AudioKey,
	volume := 0.0,
	position := Vector2.ZERO,
	vary_pitch := false
) -> AudioStreamPlayer:
	
	if not AudioData.sounds.has(sound):
		push_warning("Sound not found: %s" % str(sound))
		return null
	
	var audio_key = AudioData.sounds[sound]
	var player = AudioStreamPlayer.new()
	player.stream = audio_key["stream"]
	
	match audio_key["type"]:
		AudioData.Type.SOUND: player.bus = "SFX"
		AudioData.Type.MUSIC_INTRO: player.bus = "Music"
		AudioData.Type.MUSIC_LOOP: player.bus = "Music"
	
	player.volume_db = volume
	
	# tiny variation in pitch for variety
	if vary_pitch:
		player.pitch_scale = randf_range(0.8, 1.2)
	
	# pan position in world space - INVALID FOR AudioSteamPlayer (not -2D)
	#player.position = position
	
	if audio_key["type"] == AudioData.Type.MUSIC_LOOP:
		player.stream.loop = true
	else:
		player.finished.connect(func():
			if players.has(sound):
				players[sound].erase(player)
				
			player.queue_free()
		)
	
	# set the players dictionary
	if not players.has(sound):
		players[sound] = []
	
	players[sound].append(player)
	
	add_child(player)
	player.play()
	
	return player


# Stops the sound audio.
func stop(sound: AudioData.AudioKey):
	if not players.has(sound):
		return
	
	for player in players[sound]:
		player.stop()
		player.queue_free()
	
	players.erase(sound)


# Plays sound of type: Music.
func play_music(music: AudioData.Music):
	var dict = AudioData.music_map.get(music)
	
	if dict == null:
		return
	
	var intro_key = dict.get("intro")
	var intro_player: AudioStreamPlayer
	var intro_length: float
	
	current_music = music
	
	if music_timer:
		music_timer.stop()
		music_timer.queue_free()
		music_timer = null
	
	music_timer = Timer.new()
	
	if intro_key != null:
		intro_player = play(intro_key)
		intro_length = intro_player.stream.get_length()
		music_timer.one_shot = true
		music_timer.wait_time = intro_length
	
	add_child(music_timer)
	
	var timer = music_timer
	
	timer.timeout.connect(func():
		play(dict["loop"])
		timer.queue_free()
		
		if music_timer == timer:
			music_timer = null
	)
	
	timer.start()


# Stops the music audio.
func stop_music(music: AudioData.Music):
	var dict = AudioData.music_map.get(music)
	
	if dict == null:
		return
	
	var intro_key = dict.get("intro")
	
	current_music = AudioData.Music.NONE
	
	if music_timer:
		music_timer.stop()
		music_timer.queue_free()
		music_timer = null
	
	if intro_key != null:
		stop(dict["intro"])
	
	stop(dict["loop"])


# Stops any and all music playing. Nuclear option. Clean slate. Tabula rasa.
func stop_all_music():
	for music in AudioData.Music.values():
		stop_music(music)


# Checks if any music is currently playing.
func is_any_music_playing() -> bool:
	for id in players.keys():
		var type = AudioData.sounds[id]["type"]
		var is_music_intro: bool = type == AudioData.Type.MUSIC_INTRO
		var is_music_loop: bool = type == AudioData.Type.MUSIC_LOOP
		
		if is_music_intro or is_music_loop:
			return true
	
	return false


# Checks if specific music is playing.
func is_music_playing(music: AudioData.Music) -> bool:
	return current_music == music


# Checks if specific sound (or music) is playing.
func is_playing(sound: AudioData.AudioKey) -> bool:
	for bus_player in players.values():
		for player in bus_player:
			if player.playing and player.stream == AudioData.sounds[sound]["stream"]:
				return true
	
	return false


# Primes all looped music (prevents game loop stuttering on Web builds).
# Does this by playing sound for one game frame.
func prime_audio():
	for sound in AudioData.sounds.keys():
		if AudioData.sounds[sound]["type"] == AudioData.Type.MUSIC_LOOP:
			var muted_volume: float = -80.0
			
			play(sound, muted_volume)
			await get_tree().process_frame
			stop(sound)
