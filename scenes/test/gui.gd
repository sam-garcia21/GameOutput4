extends Control

@onready var command_main_list: ItemList = $CommandLists/MainList
@onready var command_sub_list: ItemList = $CommandLists/SubList
@onready var log: Label = $Status/LogBox/Log

signal command_chosen(command: int, subcommand: int)

var curr_hero_name: String
var skill_list: Array[AttackData]
var item_list: Array

var mainCommand

func _set_hero(hero: Hero) -> void:
	curr_hero_name = hero.fighter_name
	skill_list = hero.skills
	item_list = hero.skills

func _reset_command_lists() -> void:
	command_main_list.deselect_all()
	command_sub_list.deselect_all()
	_use_main_list()
	
func _clear_command_lists() -> void:
	command_main_list.visible = false
	command_sub_list.visible = false

func _on_command_list_item_activated(index: int) -> void:
	if index == 1:
		mainCommand = index
		_use_sub_list()
	else:
		_clear_command_lists()
		emit_signal("command_chosen", index, 0)
	

func _on_command_sub_list_item_activated(index: int) -> void:
	if index != command_sub_list.item_count - 1:
		_clear_command_lists()
		emit_signal("command_chosen", mainCommand, index)
	else:
		_use_main_list()

func _use_main_list():
	log.text = "It's " + curr_hero_name + "'s turn!"
	command_main_list.visible = true
	command_sub_list.visible = false
	_make_unselectable(command_sub_list)
	_make_selectable(command_main_list)
	
func _use_sub_list():
	command_sub_list.visible = true
	_make_unselectable(command_main_list)
	_make_selectable(command_sub_list)
	command_sub_list.clear()
	if mainCommand == 1:
		for i in skill_list:
			command_sub_list.add_item(i.attack_name)
		command_sub_list.add_item("Back")
		
func _make_selectable(list: ItemList):
	list.focus_mode = Control.FOCUS_ALL
	list.mouse_filter = Control.MOUSE_FILTER_STOP
	list.grab_focus()
	
func _make_unselectable(list: ItemList):
	list.focus_mode = Control.FOCUS_NONE
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_sub_list_item_selected(index: int) -> void:
	if mainCommand == 1:
		if index < skill_list.size():
			log.text = skill_list[index].description
		else:
			log.text = "Go back."
			
