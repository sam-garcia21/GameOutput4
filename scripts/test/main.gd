extends Node2D
## Sandbox for the player team (no battle handler needed).
## Keys: 1-5 use a command, SPACE = dummy attacks Kai, ENTER = dummy attacks Mira.
## Dodge/attack buttons: Z (Kai), X (Mira).
## Run with user arg `-- --autotest` to script a full run with auto timing.

signal turn_ended
signal target_chosen(target: int)

@onready var gui: Control = $GUI
@onready var command_lists: Control = $GUI/CommandLists
@onready var command_main_list: ItemList = $GUI/CommandLists/MainList
@onready var command_sub_list: ItemList = $GUI/CommandLists/SubList
@onready var log: Label = $GUI/Status/LogBox/Log
@onready var selector: Sprite2D = $GUI/Selector
@onready var win_screen: Control = $GUI/WinScreen
@onready var lose_screen: Control = $GUI/LoseScreen

var kai: Kai
var mira: Mira
var heroes: Array = []
var enemies: Array = []
var fighters: Array = []
var status: Label
var busy := false
#var commands: Array = []        # [hero, attack]
var turn_order: Array = []
var is_player_win = false
var SPEED_NUMBER = 100

var targets: Array
var chosen_target_index = 0
var is_choosing_target = false
var is_command_chosen = false

func _ready() -> void:
	kai = Kai.new()
	mira = Mira.new()
	var dummy = DummyEnemy.new()
	var dummy2 = DummyEnemy.new()
	heroes = [kai, mira]
	enemies = [dummy, dummy2]
	fighters = [kai, mira, dummy, dummy2]
	kai.position = Vector2(260, 320)
	mira.position = Vector2(140, 420)
	dummy.position = Vector2(900, 300)
	dummy2.position = Vector2(1000, 350)
	for i in fighters.size():
		add_child(fighters[i])
		fighters[i].log_message.connect(_log)
		turn_order.append([SPEED_NUMBER/fighters[i].spd, i])
	kai.partner = mira
	mira.partner = kai
	#for h in heroes:
		#for a in h.attacks:
			#commands.append([h, a])

	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(20, 10)
	layer.add_child(status)
	#layer.add_child(log_label)
	#var help := Label.new()
	#help.position = Vector2(20, 300)
	#var lines := ["Z = Kai button, X = Mira button   |   SPACE: dummy hits Kai   ENTER: dummy hits Mira"]
	#for i in commands.size():
		#lines.append("%d: %s - %s" % [i + 1, commands[i][0].fighter_name, commands[i][1].attack_name])
	#help.text = "\n".join(lines)
	#layer.add_child(help)
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
			win_screen.visible = true
		else :
			lose_screen.visible = true
	else:
		var current = turn_order[0]
		var i = current[1]
		var curr_fighter = fighters[i]
		if curr_fighter.hp > 0:
			if curr_fighter is Hero:
				await _choose_command(curr_fighter)
			else :
				await _run_dummy(curr_fighter)
			turn_order[0] = [current[0] + SPEED_NUMBER/fighters[i].spd, i]
		else:
			if curr_fighter is Hero:
				heroes.erase(curr_fighter)
			else:
				enemies.erase(curr_fighter)
			turn_order.remove_at(0)
		turn_order.sort_custom(sort_by_speed)
		_start_turn()

func _process(_d: float) -> void:
	var kai_hp = $GUI/Status/KaiStatus/HP
	kai_hp.text = "HP: %d/%d" % [kai.hp, kai.max_hp]
	var mira_hp = $GUI/Status/MiraStatus/HP
	mira_hp.text = "HP: %d/%d" % [mira.hp, mira.max_hp]
	status.text = "HP: "
	for i in enemies.size():
		status.text += "Dummy %d/%d    " % [enemies[i].hp, enemies[i].max_hp]

func _log(t: String) -> void:
	log.text = t
	print(t)
	
func _unhandled_key_input(event: InputEvent) -> void:
	if is_command_chosen:
		get_viewport().set_input_as_handled()
		is_command_chosen = false
		return
	if not is_choosing_target or not event.is_pressed():
		return
	var k: int = event.keycode
	if k == KEY_ESCAPE:
		emit_signal("target_chosen", -1)
	elif k == KEY_UP:
		_select_target(-1)
	elif k == KEY_DOWN:
		_select_target(1)
	elif k == KEY_ENTER:
		emit_signal("target_chosen", chosen_target_index)
		
func _use_selector(atk_data: AttackData) -> void:
	if atk_data.target_type == AttackData.Target.ENEMY:
		targets = enemies
	elif atk_data.target_type == AttackData.Target.ALLY:
		targets = heroes
	is_choosing_target = true
	selector.visible = true
	chosen_target_index = 0
	_log("Choose a target.")
	_select_target(0)

func _select_target(new_index: int) -> void:
	chosen_target_index = (chosen_target_index + new_index + targets.size()) % targets.size()
	selector.position = targets[chosen_target_index].position
	
func _get_attack_data(hero: Hero, command: int, subcommand: int) -> AttackData:
	var cmd = hero.turn_commands[command]
	var atk_data: AttackData
	print(command, subcommand, cmd)
	if (cmd == "Attack"):
		atk_data = hero.basic_attack
	elif (cmd == "Skills"):
		atk_data = hero.skills[subcommand]
	else:
		atk_data = hero.basic_attack
	return atk_data
	
func _choose_command(hero: Hero) -> void:
	var cmd
	var target = -1
	var atk_data: AttackData
	while (target == -1):
		command_lists.position = hero.position + Vector2(80, -160)
		gui._set_hero(hero)
		gui._reset_command_lists()
		cmd = await gui.command_chosen
		atk_data = _get_attack_data(hero, cmd[0], cmd[1])
		is_command_chosen = true
		_use_selector(atk_data)
		target = await target_chosen
		is_choosing_target = false
		selector.visible = false
	await _run_command(hero, atk_data, target)

func _run_command(hero: Hero, atk_data: AttackData, target_index: int) -> void:
	busy = true

	var target = targets[target_index]
	await hero.perform_attack(atk_data, target)
	busy = false

func _run_dummy(enemy: DummyEnemy) -> void:
	busy = true
	# can change enemy ai for choosing target here
	var h = randi_range(0, heroes.size() - 1)
	var target = heroes[h]
	await enemy.attack(target)
	busy = false
	
func _is_game_over() -> bool:
	var no_hp = true
	for h in heroes:
		if h.hp != 0:
			no_hp = false
	if no_hp:
		return true
	no_hp = true
	for e in enemies:
		if e.hp != 0:
			no_hp = false
	if no_hp:
		is_player_win = true
		return true
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
