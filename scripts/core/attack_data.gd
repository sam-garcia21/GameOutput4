class_name AttackData
extends Resource
## Describes one command a hero (or enemy) can use. Pure data - no logic.
## The battle menu can read name/description to build buttons.

enum Kind { DAMAGE, HEAL, BROS }
enum Target { ENEMY, ALLY, SELF }
enum Status { NONE, POISON, BLIND} # i might change if no time to implement

@export var attack_name: String = "Attack"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.DAMAGE
@export var target_type: Target = Target.ENEMY
## Base power. Damage = attacker ATK * power/100 (see Fighter.calc_damage).
## For heals this is the HP restored at 1.0x timing.
@export var power: float = 100.0
## Number of timed hits (each hit asks for its own button press).
@export var hits: int = 1
## Seconds the timing ring takes to close for each hit.
@export var window_time: float = 0.6
## Colour of the timing ring (helps players tell attacks apart).
@export var color: Color = Color.WHITE
## Status effect from attack
@export var status: int = Status.NONE
## Duration of status effect when inflicted
@export var status_duration: int = 0
## Chance of inflicting status effect
@export var status_chance: float = 0

static func make(n: String, desc: String, k: Kind, p: float, h: int = 1, t: Target = Target.ENEMY, c: Color = Color.WHITE, s: int = Status.NONE, sd: int = 0, sc: int = 0) -> AttackData:
	var a := AttackData.new()
	a.attack_name = n
	a.description = desc
	a.kind = k
	a.power = p
	a.hits = h
	a.target_type = t
	a.color = c
	a.status = s
	a.status_duration = sd
	a.status_chance = sc
	return a
