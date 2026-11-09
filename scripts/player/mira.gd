class_name Mira
extends Hero
## Hero B - fast support fighter. Button: X.

func _init() -> void:
	fighter_name = "Mira"
	max_hp = 90
	atk = 20
	def = 4
	spd = 14
	body_color = Color(0.25, 0.5, 0.9)
	input_action = &"hero_b"
	input_key = KEY_X
	ranged = true

func _ready() -> void:
	super._ready()
	# Huntress 2 by LuizMelo (CC0). 100px frames; feet at (51,67).
	var d := "res://assets/player/mira/"
	setup_sprites({
		"idle": [d + "Idle.png", 10, 10.0, true],
		"attack1": [d + "Attack.png", 6, 16.0, false],
		"hit": [d + "GetHit.png", 3, 12.0, false],
		"jump": [d + "Jump.png", 2, 8.0, false],
		"death": [d + "Death.png", 10, 10.0, false],
	}, Vector2(51, 67), 3.2)
	arrow_texture = load(d + "Arrow.png")

func _setup_attacks() -> void:
	basic_attack = AttackData.make("Bow Shot", "Two fast slashes, each timed.", AttackData.Kind.DAMAGE, 80.0, 2, AttackData.Target.ENEMY, Color(0.4, 0.8, 1))
	skills = [
		AttackData.make("Poison Arrow", "An arrow with a chance to poison, better timing for more damage.", AttackData.Kind.DAMAGE, 80.0, 2, AttackData.Target.ENEMY, Color(0.4, 0.8, 1), [
			StatusEffectData.make("Poison", "Deals damage every turn", 5, StatusEffectData.Kind.POISON, 5, 1.0, 2, 0)
		], 5),
		AttackData.make("Mend", "Heal an ally. Better timing heals more.", AttackData.Kind.HEAL, 45.0, 1, AttackData.Target.ALLY, Color(0.4, 1, 0.5), [
			
		], 10),
	]
