extends Node

# PROPERTIES

enum AudioKey {
	SILENCE_INTRO,
	SILENCE_LOOP,
	BLOODYTEARS_INTRO,
	BLOODYTEARS_LOOP,
	MONSTERDANCE,
	ATTACK_SWING,
	ATTACK_KILL,
	ATTACK_MISS,
	HOWL
}

enum Music {
	NONE, SILENCE, BLOODYTEARS, MONSTERDANCE
}

enum Type {
	SOUND, MUSIC_INTRO, MUSIC_LOOP
}

var music_map := {
	Music.SILENCE: {
		"intro": AudioKey.SILENCE_INTRO,
		"loop": AudioKey.SILENCE_LOOP
	},
	Music.BLOODYTEARS: {
		"intro": AudioKey.BLOODYTEARS_INTRO,
		"loop": AudioKey.BLOODYTEARS_LOOP
	},
	Music.MONSTERDANCE: {
		"intro": null,
		"loop": AudioKey.MONSTERDANCE
	}
}

var sounds := {
	AudioKey.SILENCE_INTRO: {
		"type": Type.MUSIC_INTRO,
		"stream": preload("res://assets/sounds/silence_intro.ogg")
	},
	AudioKey.SILENCE_LOOP: {
		"type": Type.MUSIC_LOOP,
		"stream": preload("res://assets/sounds/silence_loop.ogg")
	},
	AudioKey.BLOODYTEARS_INTRO: {
		"type": Type.MUSIC_INTRO,
		"stream": preload("res://assets/sounds/bloodytears_intro.ogg")
	},
	AudioKey.BLOODYTEARS_LOOP: {
		"type": Type.MUSIC_LOOP,
		"stream": preload("res://assets/sounds/bloodytears_loop.ogg")
	},
	AudioKey.MONSTERDANCE: {
		"type": Type.MUSIC_LOOP,
		"stream": preload("res://assets/sounds/monsterdance.ogg")
	},
	AudioKey.ATTACK_SWING: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/attack_swing.ogg")
	},
	AudioKey.ATTACK_KILL: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/attack_kill.ogg")
	},
	AudioKey.ATTACK_MISS: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/attack_miss.ogg")
	},
	AudioKey.HOWL: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/howl.ogg")
	}
}
