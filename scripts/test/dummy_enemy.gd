class_name DummyEnemy
extends Fighter
## Stand-in enemy for testing the player side. Enemy teammates: this shows
## the one call you need - `await target.receive_attack(self, power)`.

func _init() -> void:
	fighter_name = "Training Dummy"
	max_hp = 200
	atk = 18
	def = 3
	spd = 10
	body_color = Color(0.5, 0.7, 0.3)

func attack(target: Hero) -> void:
	await target.receive_attack(self, 100.0, [])
