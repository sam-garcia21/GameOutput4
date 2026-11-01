extends Node2D
## Sandbox for the player team (no battle handler needed).
## Keys: 1-5 use a command, SPACE = dummy attacks Kai, ENTER = dummy attacks Mira.
## Dodge/attack buttons: Z (Kai), X (Mira).
## Run with user arg `-- --autotest` to script a full run with auto timing.

var kai: Kai
var mira: Mira
var dummy: DummyEnemy
var log_label: RichTextLabel
var status: Label
var busy := false
var commands: Array = []        # [hero, attack]

func _ready() -> void:
	kai = Kai.new()
	mira = Mira.new()
	dummy = DummyEnemy.new()
	kai.position = Vector2(260, 420)
	mira.position = Vector2(140, 520)
	dummy.position = Vector2(900, 470)
	for f in [kai, mira, dummy]:
		add_child(f)
		f.log_message.connect(_log)
	kai.partner = mira
	mira.partner = kai
	for h in [kai, mira]:
		for a in h.attacks:
			commands.append([h, a])

	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(20, 10)
	layer.add_child(status)
	log_label = RichTextLabel.new()
	log_label.position = Vector2(20, 90)
	log_label.size = Vector2(700, 200)
	log_label.scroll_following = true
	layer.add_child(log_label)
	var help := Label.new()
	help.position = Vector2(20, 300)
	var lines := ["Z = Kai button, X = Mira button   |   SPACE: dummy hits Kai   ENTER: dummy hits Mira"]
	for i in commands.size():
		lines.append("%d: %s - %s" % [i + 1, commands[i][0].fighter_name, commands[i][1].attack_name])
	help.text = "\n".join(lines)
	layer.add_child(help)

	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()

func _process(_d: float) -> void:
	status.text = "Kai %d/%d    Mira %d/%d    Dummy %d/%d" % [kai.hp, kai.max_hp, mira.hp, mira.max_hp, dummy.hp, dummy.max_hp]

func _log(t: String) -> void:
	log_label.append_text(t + "\n")
	print(t)

func _unhandled_key_input(event: InputEvent) -> void:
	if busy or not event.is_pressed():
		return
	var k: int = event.keycode
	if k >= KEY_1 and k < KEY_1 + commands.size():
		_run_command(k - KEY_1)
	elif k == KEY_SPACE:
		_run_dummy(kai)
	elif k == KEY_ENTER:
		_run_dummy(mira)

func _run_command(i: int) -> void:
	busy = true
	var hero: Hero = commands[i][0]
	var atk_data: AttackData = commands[i][1]
	var target: Fighter = dummy if atk_data.target_type == AttackData.Target.ENEMY else mira
	await hero.perform_attack(atk_data, target)
	busy = false

func _run_dummy(target: Hero) -> void:
	busy = true
	await dummy.attack(target)
	busy = false

# Injects button presses at each window's sweet spot (rating varies by jitter).
func _autotest() -> void:
	for h in [kai, mira]:
		h.command.started.connect(func(action: StringName, sweet: float) -> void:
			await get_tree().create_timer(sweet + randf_range(-0.12, 0.12)).timeout
			var ev := InputEventAction.new()
			ev.action = action
			ev.pressed = true
			Input.parse_input_event(ev))
	await get_tree().create_timer(0.5).timeout
	for i in commands.size():
		await _run_command(i)
	await _run_dummy(kai)
	await _run_dummy(mira)
	print("AUTOTEST DONE: Kai %d Mira %d Dummy %d" % [kai.hp, mira.hp, dummy.hp])
	get_tree().quit()
