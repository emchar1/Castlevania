extends Node

# PROPERTIES

enum AudioKey {
	SILENCE_INTRO,
	SILENCE_LOOP,
	BLOODYTEARS_INTRO,
	BLOODYTEARS_LOOP,
	MONSTERDANCE,
	SWITCHWITHME,
	ENERGIA,
	ATTACK_SWING,
	ATTACK_SWING2,
	ATTACK_KILL,
	ATTACK_MISS,
	HOWL,
	HOWL_SHORT,
	CURSE_PICKUP,
	HEALTH_PICKUP,
	LAND,
	DEATH
}

enum Music {
	NONE, SILENCE, BLOODYTEARS, MONSTERDANCE, SWITCHWITHME, ENERGIA
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
	},
	Music.SWITCHWITHME: {
		"intro": null,
		"loop": AudioKey.SWITCHWITHME
	},
	Music.ENERGIA: {
		"intro": null,
		"loop": AudioKey.ENERGIA
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
	AudioKey.SWITCHWITHME: {
		"type": Type.MUSIC_LOOP,
		"stream": preload("res://assets/sounds/switchwithme.ogg")
	},
	AudioKey.ENERGIA: {
		"type": Type.MUSIC_LOOP,
		"stream": preload("res://assets/sounds/energia.ogg")
	},
	AudioKey.ATTACK_SWING: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/attack_swing.ogg")
	},
	AudioKey.ATTACK_SWING2: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/attack_swing2.ogg")
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
	},
	AudioKey.HOWL_SHORT: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/howl_short.ogg")
	},
	AudioKey.CURSE_PICKUP: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/curse_pickup.ogg")
	},
	AudioKey.HEALTH_PICKUP: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/health_pickup.ogg")
	},
	AudioKey.LAND: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/land.ogg")
	},
	AudioKey.DEATH: {
		"type": Type.SOUND,
		"stream": preload("res://assets/sounds/death.ogg")
	}
}
