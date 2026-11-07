extends Control

@onready var command_main_list: ItemList = $CommandLists/MainList
@onready var command_sub_list: ItemList = $CommandLists/SubList

signal command_chosen(command: int, subcommand: int)

var skill_list: Array[AttackData]
var item_list: Array

var mainCommand

func reset_command_lists() -> void:
	command_main_list.deselect_all()
	command_sub_list.deselect_all()
	use_main_list()
	
func clear_command_lists() -> void:
	command_main_list.visible = false
	command_sub_list.visible = false

func _on_command_list_item_activated(index: int) -> void:
	if index == 1:
		mainCommand = index
		use_sub_list()
	else:
		clear_command_lists()
		emit_signal("command_chosen", index, 0)
	

func _on_command_sub_list_item_activated(index: int) -> void:
	if index != command_sub_list.item_count - 1:
		clear_command_lists()
		emit_signal("command_chosen", mainCommand, index)
	else:
		use_main_list()

func use_main_list():
	command_main_list.visible = true
	command_sub_list.visible = false
	make_unselectable(command_sub_list)
	make_selectable(command_main_list)
	
func use_sub_list():
	command_sub_list.visible = true
	make_unselectable(command_main_list)
	make_selectable(command_sub_list)
	command_sub_list.clear()
	if mainCommand == 1:
		for i in skill_list:
			command_sub_list.add_item(i.attack_name)
		command_sub_list.add_item("Back")
		
func make_selectable(list: ItemList):
	list.focus_mode = Control.FOCUS_ALL
	list.mouse_filter = Control.MOUSE_FILTER_STOP
	list.grab_focus()
	
func make_unselectable(list: ItemList):
	list.focus_mode = Control.FOCUS_NONE
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
