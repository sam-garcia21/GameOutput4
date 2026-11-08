class_name ItemData
extends Resource

enum Kind { DAMAGE, HEAL }
enum Target { ENEMY, ALLY, SELF, ALL}

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.HEAL
@export var target_type: Target = Target.ALLY
## Base power. Damage = attacker ATK * power/100 (see Fighter.calc_damage).
## For heals this is the HP restored at 1.0x timing.
@export var power: float = 100.0
@export var status_effects: Array[StatusEffectData]

static func make(n: String, desc: String, k: Kind, p: int, t: Target = Target.ENEMY, se: Array[StatusEffectData] = []) -> ItemData:
	var a := ItemData.new()
	a.item_name = n
	a.description = desc
	a.kind = k
	a.power = p
	a.target_type = t
	a.status_effects = se
	return a
