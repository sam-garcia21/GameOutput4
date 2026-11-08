class_name Inventory
extends Node

var items: Array[ItemData] = []

func _init():
	var potion = ItemData.make(
		"Potion", "Heals 30 HP.", ItemData.Kind.HEAL, 30, 1, ItemData.Target.ALLY
	)
	for i in range(5):
		items.append(potion)
	var bomb = ItemData.make(
		"Bomb", "Deals 100 HP on a single enemy.", ItemData.Kind.DAMAGE, 100, 1, ItemData.Target.ENEMY
	)
	for i in range(5):
		items.append(bomb)
		
func _use_item(index: int, target: Fighter):
	var item = items[index]
	if item.kind == ItemData.Kind.HEAL:
		target.heal(item.power)
	elif item.kind == ItemData.Kind.DAMAGE:
		target.take_damage(item.power)
	items.remove_at(index)
