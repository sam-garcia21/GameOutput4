class_name Morishima
extends Fighter
## Stand-in enemy for testing the player side. Enemy teammates: this shows
## the one call you need - `await target.receive_attack(self, power)`.

func _init() -> void:
	fighter_name = "Morishima"
	max_hp = 210
	atk = 27
	def = 5
	spd = 15
	body_color = Color(0.5, 0.7, 0.3)
	add_child(timer)

func _ready() -> void:
	super._ready()
	var d := "res://assets/enemy/morishima/"
	setup_sprites({
		"idle": [d + "Idle.png", 8, 10.0, true],
		"attack1": [d + "Attack1.png", 6, 16.0, false],
		"hit": [d + "Take Hit.png", 3, 12.0, false],
		"jump": [d + "Jump.png", 2, 8.0, false],
		"death": [d + "Death.png", 10, 10.0, false],
	}, Vector2(100, 120), 3.2)
	
func attack(target: Hero) -> void:
	await target.receive_attack(self, 100.0, [])
	sprite.play("attack1")
	await sprite.animation_finished
	sprite.play("idle")

func poison(target: Hero) -> void:
	await target.receive_attack(self, 60.0, [(StatusEffectData.make("Poison", "Deals damage every turn", 5, StatusEffectData.Kind.POISON, 5, 1.0, 2, 0))])
	sprite.play("attack1")
	await sprite.animation_finished
	sprite.play("idle")
