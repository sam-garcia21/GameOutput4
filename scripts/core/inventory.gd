class_name Inventory
extends Node

var items: Array[ItemData] = []

func _init():
	var potion = ItemData.make(
		"Potion", "Heals 30 HP.", ItemData.Kind.HEAL, 30, ItemData.Target.ALLY
	)
	for i in range(5):
		items.append(potion)
	var death = ItemData.make(
		"??? Potion", "???", ItemData.Kind.DAMAGE, 999, ItemData.Target.ALLY
	)
	for i in range(5):
		items.append(death)
	var bomb = ItemData.make(
		"Bomb", "Deals 100 HP on a single enemy.", ItemData.Kind.DAMAGE, 100, ItemData.Target.ENEMY
	)
	for i in range(5):
		items.append(bomb)
	var poison = ItemData.make(
		"Poison Bomb", "Inflicts poison.", ItemData.Kind.DAMAGE, 0, ItemData.Target.ALL,
		[StatusEffectData.make(
			"Poison", "", 10, StatusEffectData.Kind.POISON, 5, 1, 2, 0
		)]
	)
	for i in range(3):
		items.append(poison)
	var para = ItemData.make(
		"Parlyz Bomb", "Inflicts paralysis.", ItemData.Kind.DAMAGE, 0, ItemData.Target.ALL,
		[StatusEffectData.make(
			"Paralysis", "", 0, StatusEffectData.Kind.PARALYSIS, 5, 1, 9, 0
		)]
	)
	for i in range(3):
		items.append(para)
	var blind = ItemData.make(
		"Blind Bomb", "Inflicts blind.", ItemData.Kind.DAMAGE, 0, ItemData.Target.ALL,
		[StatusEffectData.make(
			"Blind", "", 0, StatusEffectData.Kind.BLIND, 5, 1, 3, 0
		)]
	)
	for i in range(3):
		items.append(blind)
		
func _use_item(index: int, target: Fighter):
	var item = items[index]
	if item.kind == ItemData.Kind.HEAL:
		target.heal(item.power)
	elif item.kind == ItemData.Kind.DAMAGE:
		target.take_damage(item.power)
	elif item.kind == ItemData.Kind.MP_RESTORE:
		target._change_mp(item.power)
	for s in item.status_effects:
		target._apply_effect(s)
	items.remove_at(index)
