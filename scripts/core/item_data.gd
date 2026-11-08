class_name ItemData
extends Resource

enum Kind { DAMAGE, HEAL }
enum Target { ENEMY, ALLY, SELF }

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.HEAL
@export var target_type: Target = Target.ALLY
## Base power. Damage = attacker ATK * power/100 (see Fighter.calc_damage).
## For heals this is the HP restored at 1.0x timing.
@export var power: float = 100.0
## Number of timed hits (each hit asks for its own button press).
@export var hits: int = 1

static func make(n: String, desc: String, k: Kind, p: float, h: int = 1, t: Target = Target.ENEMY) -> ItemData:
	var a := ItemData.new()
	a.item_name = n
	a.description = desc
	a.kind = k
	a.power = p
	a.hits = h
	a.target_type = t
	return a
