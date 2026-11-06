extends Node2D
## Sandbox for the player team (no battle handler needed).
## Keys: 1-5 use a command, SPACE = dummy attacks Kai, ENTER = dummy attacks Mira.
## Dodge/attack buttons: Z (Kai), X (Mira).
## Run with user arg `-- --autotest` to script a full run with auto timing.

signal turn_ended
signal target_chosen(target: int)

@onready var gui: Control = $GUI
@onready var command_list: ItemList = $GUI/CommandList
@onready var command_sub_list: ItemList = $GUI/CommandSubList
@onready var log: Label = $GUI/Log
@onready var selector: Sprite2D = $GUI/Selector

var kai: Kai
var mira: Mira
var dummy: DummyEnemy
var heroes: Array = []
var enemies: Array = []
var fighters: Array = []
var status: Label
var busy := false
var commands: Array = []        # [hero, attack]
var turn_order: Array = []
var is_player_win = false
var SPEED_NUMBER = 100
var chosen_enemy_index = 0
var is_choosing_enemy = false

func _ready() -> void:
	kai = Kai.new()
	mira = Mira.new()
	dummy = DummyEnemy.new()
	heroes = [kai, mira]
	enemies = [dummy]
	fighters = [kai, mira, dummy]
	kai.position = Vector2(260, 420)
	mira.position = Vector2(140, 520)
	dummy.position = Vector2(900, 470)
	for i in fighters.size():
		add_child(fighters[i])
		fighters[i].log_message.connect(_log)
		turn_order.append([SPEED_NUMBER/fighters[i].spd, i])
	kai.partner = mira
	mira.partner = kai
	for h in heroes:
		for a in h.attacks:
			commands.append([h, a])

	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(20, 10)
	layer.add_child(status)
	#layer.add_child(log_label)
	var help := Label.new()
	help.position = Vector2(20, 300)
	var lines := ["Z = Kai button, X = Mira button   |   SPACE: dummy hits Kai   ENTER: dummy hits Mira"]
	for i in commands.size():
		lines.append("%d: %s - %s" % [i + 1, commands[i][0].fighter_name, commands[i][1].attack_name])
	help.text = "\n".join(lines)
	layer.add_child(help)
	_start_turn()
	#if "--autotest" in OS.get_cmdline_user_args():
		#_autotest()
		
func sort_by_speed(a: Array, b: Array) -> bool:
	if a[0] < b[0]:
		return true
	return false
	
func _start_turn() -> void:
	if _is_game_over():
		if is_player_win:
			pass
		else :
			pass
	else:
		var current = turn_order[0]
		var i = current[1]
		var curr_fighter = fighters[i]
		if curr_fighter is Hero:
			await _choose_command(curr_fighter)
		else :
			await _run_dummy()
		turn_order[0] = [current[0] + SPEED_NUMBER/fighters[i].spd, i]
		turn_order.sort_custom(sort_by_speed)

func _process(_d: float) -> void:
	status.text = "Kai %d/%d    Mira %d/%d    Dummy %d/%d" % [kai.hp, kai.max_hp, mira.hp, mira.max_hp, dummy.hp, dummy.max_hp]

func _log(t: String) -> void:
	log.text = t
	print(t)
	
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_choosing_enemy or not event.is_pressed():
		return
	var k: int = event.keycode
	if k == KEY_ESCAPE:
		emit_signal("target_chosen", -1)
	elif k == KEY_UP:
		_select_enemy(max(0, chosen_enemy_index - 1))
	elif k == KEY_DOWN:
		_select_enemy(min(enemies.size() - 1, chosen_enemy_index + 1))
	elif k == KEY_ENTER:
		emit_signal("target_chosen", chosen_enemy_index)

func _select_enemy(new_index: int) -> void:
	chosen_enemy_index = new_index
	selector.position = enemies[new_index].position
	
func _choose_command(hero: Hero) -> void:
	var cmd
	var target = -1
	while (target == -1):
		command_list.deselect_all()
		command_sub_list.deselect_all()
		command_list.visible = true
		cmd = await gui.command_chosen
		command_list.visible = false
		command_sub_list.visible = false
		is_choosing_enemy = true
		_select_enemy(0)
		target = await target_chosen
	_run_command(hero, cmd[0] + cmd[1], target)

func _run_command(hero: Hero, command: int, target_index: int) -> void:
	busy = true
	var atk_data: AttackData = commands[command][1]
	var target = enemies[target_index]
	await hero.perform_attack(atk_data, target)
	_start_turn()
	busy = false

func _run_dummy() -> void:
	busy = true
	# can change enemy ai for choosing target here
	var h = randi_range(0, 1)
	var target = heroes[h]
	await dummy.attack(target)
	_start_turn()
	busy = false
	
func _is_game_over() -> bool:
	return false

# Injects button presses at each window's sweet spot (rating varies by jitter).
#func _autotest() -> void:
	#for h in [kai, mira]:
		#h.command.started.connect(func(action: StringName, sweet: float) -> void:
			#await get_tree().create_timer(sweet + randf_range(-0.12, 0.12)).timeout
			#var ev := InputEventAction.new()
			#ev.action = action
			#ev.pressed = true
			#Input.parse_input_event(ev))
	#await get_tree().create_timer(0.5).timeout
	#for i in commands.size():
		#await _run_command(i)
	#await _run_dummy(kai)
	#await _run_dummy(mira)
	#print("AUTOTEST DONE: Kai %d Mira %d Dummy %d" % [kai.hp, mira.hp, dummy.hp])
	#get_tree().quit()
