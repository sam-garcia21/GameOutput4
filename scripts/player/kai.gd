class_name Kai
extends Hero
## Hero A - front-line brawler. Button: Z.

func _init() -> void:
	fighter_name = "Kai"
	max_hp = 120
	atk = 24
	def = 8
	spd = 9
	body_color = Color(0.85, 0.25, 0.2)
	input_action = &"hero_a"
	input_key = KEY_Z

func _ready() -> void:
	super._ready()
	# Fantasy Warrior by LuizMelo (CC0). 162px frames; feet at (85,101).
	var d := "res://assets/player/kai/"
	setup_sprites({
		"idle": [d + "Idle.png", 10, 10.0, true],
		"attack1": [d + "Attack1.png", 7, 18.0, false],
		"hit": [d + "TakeHit.png", 3, 12.0, false],
		"jump": [d + "Jump.png", 3, 10.0, false],
		"death": [d + "Death.png", 7, 10.0, false],
	}, Vector2(85, 101), 2.5)

func _setup_attacks() -> void:
	basic_attack = AttackData.make("Slash", "One slash. Time the landing!", AttackData.Kind.DAMAGE, 120.0, 1, AttackData.Target.ENEMY, Color(1, 0.5, 0.3))
	skills = [
		AttackData.make("Blinding Slash", "One slash. Can cause blindness.", AttackData.Kind.DAMAGE, 120.0, 1, AttackData.Target.ENEMY, Color(1, 0.5, 0.3), [
			StatusEffectData.make("Blind", "Higher chance to miss", 5, StatusEffectData.Kind.BLIND, 5, 0.7, 3, 0)
		]),
		AttackData.make("Double Slash", "Two sword slashes, each timed.", AttackData.Kind.DAMAGE, 70.0, 3, AttackData.Target.ENEMY, Color(1, 0.3, 0.1)),
		AttackData.make("Duo Attack", "Both heroes strike together.", AttackData.Kind.BROS, 160.0, 2, AttackData.Target.ENEMY, Color(1, 0.85, 0.2)),
	]
