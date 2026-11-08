extends Control

@onready var command_main_list: ItemList = $CommandLists/MainList
@onready var command_sub_list: ItemList = $CommandLists/SubList
@onready var log: Label = $Status/LogBox/Log
@onready var timer: Timer = $Timer

signal command_chosen(command: int, subcommand: int)

var curr_hero_name: String
var command_list: Array
var skill_list: Array[AttackData]
var item_list: Array[ItemData]

var mainCommand

func _log(s: String, time: int) -> void:
	if (not timer.is_stopped()):
		await timer.timeout
	print(s)
	log.text = s
	if (time > 0):
		timer.wait_time = time
		timer.start()
		await timer.timeout

func _set_hero(hero: Hero) -> void:
	curr_hero_name = hero.fighter_name
	command_list = hero.turn_commands
	skill_list = hero.skills

func _reset_command_lists() -> void:
	command_main_list.deselect_all()
	command_sub_list.deselect_all()
	_use_main_list()
	
func _clear_command_lists() -> void:
	command_main_list.visible = false
	command_sub_list.visible = false

func _on_command_list_item_activated(index: int) -> void:
	if index == 1 || index == 2:
		mainCommand = index
		_use_sub_list()
	elif index == command_list.size() - 1:
		_log("There's no running from this battle.", 0)
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
	_log("It's " + curr_hero_name + "'s turn!", 0)
	command_main_list.visible = true
	command_sub_list.visible = false
	_make_unselectable(command_sub_list)
	_make_selectable(command_main_list)
	command_main_list.clear()
	for i in command_list:
		command_main_list.add_item(i)
	
func _use_sub_list():
	command_sub_list.visible = true
	_make_unselectable(command_main_list)
	_make_selectable(command_sub_list)
	command_sub_list.clear()
	if mainCommand == 1:
		for i in skill_list:
			command_sub_list.add_item(i.attack_name)
	elif mainCommand == 2:
		for i in item_list:
			command_sub_list.add_item(i.item_name)
	command_sub_list.add_item("Back")
		
func _make_selectable(list: ItemList):
	list.focus_mode = Control.FOCUS_ALL
	list.mouse_filter = Control.MOUSE_FILTER_STOP
	list.grab_focus()
	
func _make_unselectable(list: ItemList):
	list.focus_mode = Control.FOCUS_NONE
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_sub_list_item_selected(index: int) -> void:
	var list: Array
	if mainCommand == 1:
		list = skill_list
	elif mainCommand == 2:
		list = item_list

	if index < list.size():
		_log(list[index].description, 0)
	else:
		_log("Go back.", 0)
			
