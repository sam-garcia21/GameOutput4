class_name StatusEffectData
extends Resource

enum Kind { NONE, POISON, PARALYSIS, BLIND } # i might change if no time to implement

@export var status_effect_name: String = ""
@export_multiline var description: String = ""
@export var power: int = 0
@export var kind: Kind = Kind.NONE
@export var duration: int = 0
@export var chance: float = 100.0
@export var icon_texture: String
@export var icon_rect: Rect2

static func make(n: String, desc: String, p: int, k: Kind, d: int, c: float, x: int, y: int) -> StatusEffectData:
	var a := StatusEffectData.new()
	a.status_effect_name = n
	a.description = desc
	a.power = p
	a.kind = k
	a.duration = d
	a.chance = c
	a.icon_texture = "res://assets/IconSet.png"
	a.icon_rect = Rect2(x * 32, y * 32, 32, 32)
	return a
