extends Node2D
## Sandbox for the player team (no battle handler needed).
## Keys: 1-5 use a command, SPACE = dummy attacks Kai, ENTER = dummy attacks Mira.
## Dodge/attack buttons: Z (Kai), X (Mira).
## Run with user arg `-- --autotest` to script a full run with auto timing.

signal target_chosen(target: int)

@onready var gui: Control = $GUI
@onready var command_lists: Control = $GUI/CommandLists
@onready var command_main_list: ItemList = $GUI/CommandLists/MainList
@onready var command_sub_list: ItemList = $GUI/CommandLists/SubList
@onready var selector: Sprite2D = $GUI/Selector
@onready var hp_bar: ProgressBar = $GUI/HP_Bar
@onready var win_screen: Control = $GUI/WinScreen
@onready var lose_screen: Control = $GUI/LoseScreen
@onready var statuses: HFlowContainer = $GUI/Statuses

var kai: Kai
var mira: Mira
var heroes: Array = []
var enemies: Array = []
var fighters: Array = []
var status: Label
var inventory: Inventory
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
	inventory = Inventory.new()
	gui.item_list = inventory.items
	var dummy = DummyEnemy.new()
	var dummy2 = DummyEnemy.new()
	heroes = [kai, mira]
	enemies = [dummy, dummy2]
	fighters = [kai, mira, dummy, dummy2]
	kai.position = Vector2(260, 320)
	mira.position = Vector2(140, 420)
	dummy.position = Vector2(850, 300)
	dummy2.position = Vector2(950, 400)
	for e in enemies:
		e.z_index = -2
	for i in fighters.size():
		add_child(fighters[i])
		fighters[i].log_message.connect(gui._log)
		fighters[i].died.connect(_update_died)
		fighters[i].hp_changed.connect(_update_hp)
		fighters[i].mp_changed.connect(_update_mp)
		turn_order.append([SPEED_NUMBER/fighters[i].spd, fighters[i]])
	for h in heroes:
		_update_hp(h, h.hp, h.max_hp)
		_update_mp(h, h.mp, h.max_mp)
	kai.partner = mira
	mira.partner = kai
	_start_turn()
		
func sort_by_speed(a: Array, b: Array) -> bool:
	if a[0] < b[0]:
		return true
	return false
	
func _start_turn() -> void:
	print("turn start")
	if _is_game_over():
		if is_player_win:
			win_screen.visible = true
		else :
			lose_screen.visible = true
	else:
		var current = turn_order[0]
		var i = current[1]
		var curr_fighter: Fighter = i
		print(curr_fighter.fighter_name)
		await curr_fighter.start_turn()
		if curr_fighter.hp > 0:
			if curr_fighter._has_effect(StatusEffectData.Kind.PARALYSIS).has_effect:
				gui._log("%s is paralyzed and can't move!" % [curr_fighter.fighter_name])
				await kai._wait(0.6)
			elif curr_fighter is Hero:
				await _choose_command(curr_fighter)
			else:
				await _run_dummy(curr_fighter)
			if curr_fighter.hp > 0:
				turn_order[0] = [current[0] + SPEED_NUMBER/curr_fighter.spd, i]
		turn_order.sort_custom(sort_by_speed)
		await curr_fighter.end_turn()
		if not gui.timer.is_stopped():
			await gui.timer.timeout
		kai._wait(0.5)
		_start_turn()
		
func _update_died(fighter: Fighter):
	if fighter is Hero:
		heroes.erase(fighter)
	else:
		enemies.erase(fighter)
	print(turn_order.size())
	var index = 0
	for i in range(turn_order.size()):
		if turn_order[i][1] == fighter:
			index = i
			break
	turn_order.remove_at(index)
	fighters.erase(fighter)
	print(turn_order.size())
	
func _update_hp(fighter: Fighter, hp: int, max_hp: int):
	if fighter is Kai:
		var kai_hp = $GUI/Status/KaiStatus/HP
		kai_hp.text = "HP: %d/%d" % [hp, max_hp]
	elif fighter is Mira:
		var mira_hp = $GUI/Status/MiraStatus/HP
		mira_hp.text = "HP: %d/%d" % [hp, max_hp]
		
func _update_mp(fighter: Fighter, mp: int, max_mp: int):
	if fighter is Kai:
		var kai_mp = $GUI/Status/KaiStatus/MP
		kai_mp.text = "MP: %d/%d" % [mp, max_mp]
	elif fighter is Mira:
		var mira_mp = $GUI/Status/MiraStatus/MP
		mira_mp.text = "MP: %d/%d" % [mp, max_mp]
	
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
		is_choosing_target = false
	elif k == KEY_UP:
		_select_target(-1)
	elif k == KEY_DOWN:
		_select_target(1)
	elif k == KEY_ENTER:
		emit_signal("target_chosen", chosen_target_index)
		is_choosing_target = false
		
func _use_selector(target_type: int) -> void:
	if target_type == AttackData.Target.ENEMY:
		targets = enemies
	elif target_type == AttackData.Target.ALLY:
		targets = heroes
	elif target_type == AttackData.Target.ALL:
		targets = fighters
	is_choosing_target = true
	selector.visible = true
	hp_bar.visible = true
	statuses.visible = true
	chosen_target_index = 0
	gui._log("Choose a target.")
	_select_target(0)

func _select_target(new_index: int) -> void:
	chosen_target_index = (chosen_target_index + new_index + targets.size()) % targets.size()
	var target: Fighter = targets[chosen_target_index]
	selector.position = target.position
	hp_bar.position = target.position + Vector2(-(hp_bar.size.x / 2), 10)
	hp_bar.max_value = target.max_hp
	hp_bar.value = target.hp
	var status_icons = statuses.get_children()
	for c in status_icons:
		statuses.remove_child(c)
		c.queue_free()
	for s in target.status_effects:
		print(s.status_effect_name, s.duration)
		var c = Control.new()
		var icon = Sprite2D.new()
		icon.texture = load(s.icon_texture)
		icon.region_enabled = true
		icon.region_rect = s.icon_rect
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.add_child(icon)
		c.visible = true
		statuses.add_child(c)
	print(statuses.get_children().size())
	statuses.position = target.position + Vector2(0, -150)
	
func _get_target_data(hero: Hero, command: int, subcommand: int) -> int:
	var cmd = hero.turn_commands[command]
	var target_data
	if (cmd == "Attack"):
		target_data = hero.basic_attack.target_type
	elif (cmd == "Skills"):
		target_data = hero.skills[subcommand].target_type
	elif (cmd == "Items"):
		target_data = inventory.items[subcommand].target_type
	elif (cmd == "Defend"):
		target_data = AttackData.Target.SELF
	else:
		target_data = hero.basic_attack.target_type
	return target_data
	
func _choose_command(hero: Hero) -> void:
	var cmd
	var target: Fighter = null
	var target_index = -1
	var target_data: int
	while (target_index == -1):
		command_lists.position = hero.position + Vector2(80, -160)
		gui._set_hero(hero)
		gui._reset_command_lists()
		cmd = await gui.command_chosen
		target_data = _get_target_data(hero, cmd[0], cmd[1])
		is_command_chosen = true
		if (target_data == AttackData.Target.SELF):
			target_index = 0
			target = hero
		else:
			_use_selector(target_data)
			target_index = await target_chosen
			selector.visible = false
			hp_bar.visible = false
			statuses.visible = false
	if target_data != AttackData.Target.SELF:
		target = targets[target_index]
	await _run_command(hero, cmd[0], cmd[1], target)

func _run_command(hero: Hero, main_cmd: int, sub_cmd: int, target: Fighter) -> void:
	busy = true
	var cmd = hero.turn_commands[main_cmd]
	if (cmd == "Attack"):
		var atk_data = hero.basic_attack
		await hero.perform_attack(atk_data, target)
	elif (cmd == "Skills"):
		var atk_data = hero.skills[sub_cmd]
		await hero.perform_attack(atk_data, target)
	elif (cmd == "Items"):
		await inventory._use_item(sub_cmd, target)
	elif (cmd == "Defend") :
		await hero.defend()
	busy = false

func _run_dummy(enemy: DummyEnemy) -> void:
	busy = true
	var h = randi_range(0, heroes.size() - 1)
	var target = heroes[h]
	await enemy.attack(target)
	busy = false
	
func _is_game_over() -> bool:
	if heroes.size() == 0:
		return true
	elif enemies.size() == 0:
		is_player_win = true
		return true
	return false
