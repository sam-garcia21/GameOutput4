extends Control

@onready var command_list: ItemList = $CommandList
@onready var command_sub_list: ItemList = $CommandSubList

signal command_chosen(command: int, subcommand: int)

var mainCommand

func _on_command_list_item_activated(index: int) -> void:
	if index == 1:
		mainCommand = index
		command_sub_list.visible = true
	else:
		emit_signal("command_chosen", index, 0)
	

func _on_command_sub_list_item_activated(index: int) -> void:
	if index == command_sub_list.item_count - 1:
		command_sub_list.visible = false
	else:
		emit_signal("command_chosen", mainCommand, index)
