class_name Hero
extends Fighter
## A playable party member. Handles:
##  - performing attacks with timed "action commands"
##  - defending: dodging / countering incoming enemy attacks
## Subclasses (kai.gd, mira.gd) only fill in stats and the `attacks` list.
##
## Battle-handler API (what your teammate calls):
##   await hero.perform_attack(attack_data, target)      # damage / heal / bros
##   await hero.receive_attack(attacker, power)           # called by enemy attacks

signal attack_finished

## Name of the InputMap action for this hero's button, and its default key.
@export var input_action: StringName = &"hero_a"
@export var input_key: Key = KEY_Z

## Ranged heroes (bows/magic) shoot from where they stand instead of walking up.
@export var ranged := false
var arrow_texture: Texture2D
var attacks: Array[AttackData] = []
var partner: Hero
var command: ActionCommand

const RATING_TEXT := ["Miss...", "Good!", "Great!!", "PERFECT!!!"]

func _ready() -> void:
	super._ready()
	_register_input()
	command = ActionCommand.new()
	command.position = Vector2(0, -110)
	add_child(command)
	_setup_attacks()

## Override in subclasses.
func _setup_attacks() -> void:
	pass

func _register_input() -> void:
	if InputMap.has_action(input_action):
		return
	InputMap.add_action(input_action)
	var ev := InputEventKey.new()
	ev.physical_keycode = input_key
	InputMap.action_add_event(input_action, ev)

# ---------------------------------------------------------------- OFFENSE --

func perform_attack(attack: AttackData, target: Fighter) -> void:
	match attack.kind:
		AttackData.Kind.HEAL:
			await _do_heal(attack, target)
		AttackData.Kind.BROS:
			await _do_bros(attack, target)
		_:
			await _do_damage(attack, target)
	attack_finished.emit()

func _do_damage(attack: AttackData, target: Fighter) -> void:
	log_message.emit("%s used %s on %s!" % [fighter_name, attack.attack_name, target.fighter_name])
	if not ranged:
		await _move_to(target.position + Vector2(-70, 0))
	for i in attack.hits:
		if not target.is_alive():
			break
		var rating: int = await command.run(input_action, attack.window_time, attack.color)
		_swing()
		if ranged:
			await _shoot(target)
		else:
			await _lunge()
		_apply_hit(attack.power, rating, target)
	if not ranged:
		await _move_to(home_position)

func _do_heal(attack: AttackData, target: Fighter) -> void:
	log_message.emit("%s used %s on %s!" % [fighter_name, attack.attack_name, target.fighter_name])
	var rating: int = await command.run(input_action, attack.window_time, attack.color)
	var amount := int(round(attack.power * ActionCommand.MULTIPLIER[rating] * randf_range(0.9, 1.1)))
	var gained := target.heal(amount)
	log_message.emit("%s  %s recovered %d HP." % [RATING_TEXT[rating], target.fighter_name, gained])
	await _hop()

## Combined attack: BOTH heroes must time their own button. If both land
## Great or better, the team gets a bonus.
func _do_bros(attack: AttackData, target: Fighter) -> void:
	if partner == null or not partner.is_alive():
		log_message.emit("%s needs a partner for %s!" % [fighter_name, attack.attack_name])
		return
	log_message.emit("%s and %s used %s on %s!" % [fighter_name, partner.fighter_name, attack.attack_name, target.fighter_name])
	_move_to(target.position + Vector2(-70, -30))
	await partner._move_to(target.position + Vector2(-70, 30))
	for i in attack.hits:
		if not target.is_alive():
			break
		var ratings: Array = []
		var collect := func(r: int) -> void: ratings.append(r)
		command.finished.connect(collect, CONNECT_ONE_SHOT)
		partner.command.finished.connect(collect, CONNECT_ONE_SHOT)
		command.start(input_action, attack.window_time, attack.color)
		partner.command.start(partner.input_action, attack.window_time, attack.color)
		while ratings.size() < 2:
			await get_tree().process_frame
		var avg := int(round((ratings[0] + ratings[1]) / 2.0))
		var power := attack.power * float(atk + partner.atk) / (2.0 * atk)
		if ratings[0] >= ActionCommand.Rating.GREAT and ratings[1] >= ActionCommand.Rating.GREAT:
			power *= 1.2
			log_message.emit("TEAMWORK bonus!")
		_swing()
		await _lunge()
		_apply_hit(power, avg, target)
	_move_to(home_position)
	await partner._move_to(partner.home_position)

func _apply_hit(power: float, rating: int, target: Fighter) -> void:
	var r := calc_damage(power, rating, target)
	if r.missed:
		log_message.emit("%s  ...but %s dodged!" % [RATING_TEXT[rating], target.fighter_name])
		return
	var lost := target.take_damage(r.damage, self)
	var crit := " CRITICAL HIT!" if r.crit else ""
	log_message.emit("%s  %s took %d damage.%s" % [RATING_TEXT[rating], target.fighter_name, lost, crit])

# ---------------------------------------------------------------- DEFENSE --

## Called by an enemy attack. Opens a dodge window for this hero AND an
## assist window for the partner (each uses their own button).
## Returns {damage:int, rating:int, countered:bool}.
func receive_attack(attacker: Fighter, power: float, telegraph: float = 0.7) -> Dictionary:
	var key_text: String = InputMap.action_get_events(input_action)[0].as_text_physical_keycode()
	log_message.emit("%s attacks %s!  (press %s to dodge)" % [attacker.fighter_name, fighter_name, key_text])
	var own := {"r": -1}
	var assist := {"r": -1}
	command.finished.connect(func(r: int) -> void: own.r = r, CONNECT_ONE_SHOT)
	command.start(input_action, telegraph, Color(1, 0.9, 0.3))
	var has_assist := partner != null and partner.is_alive()
	if has_assist:
		partner.command.finished.connect(func(r: int) -> void: assist.r = r, CONNECT_ONE_SHOT)
		partner.command.start(partner.input_action, telegraph, Color(0.4, 0.8, 1), true)   # silent: only the target shows a rating
	while own.r < 0 or (has_assist and assist.r < 0):
		await get_tree().process_frame

	var out := {"damage": 0, "rating": own.r, "countered": false}
	var hit := attacker.calc_damage(power, ActionCommand.Rating.GOOD, self)
	if hit.missed:
		log_message.emit("%s's attack missed!" % attacker.fighter_name)
		return out
	var factor: float = [1.0, 0.6, 0.3, 0.0][own.r]      # MISS, GOOD, GREAT, PERFECT
	if has_assist and assist.r >= ActionCommand.Rating.GOOD:
		factor *= 0.85                                    # partner's assist guard
	var dmg := int(round(hit.damage * factor))
	if own.r == ActionCommand.Rating.PERFECT:
		await _hop()
		var back := maxi(1, int(round(atk * 0.5)))
		attacker.take_damage(back, self)
		out.countered = true
		log_message.emit("PERFECT dodge! %s countered %s for %d damage!" % [fighter_name, attacker.fighter_name, back])
	elif own.r > ActionCommand.Rating.MISS:
		await _hop()
		log_message.emit("%s guarded! %s" % [fighter_name, RATING_TEXT[own.r]])
	if dmg > 0:
		out.damage = take_damage(dmg, attacker)
		log_message.emit("%s took %d damage." % [fighter_name, out.damage])
	return out

# -------------------------------------------------------------- ANIMATION --
# Tween-based placeholders; replace with AnimatedSprite2D calls once art lands.

func _move_to(pos: Vector2) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", pos, 0.25).set_trans(Tween.TRANS_SINE)
	await tw.finished

func _lunge() -> void:
	var start := position
	var tw := create_tween()
	tw.tween_property(self, "position", start + Vector2(30, 0), 0.08)
	tw.tween_property(self, "position", start, 0.08)
	await tw.finished

## Projectile flight for ranged heroes (sprite only, damage is applied after).
func _shoot(target: Fighter) -> void:
	await get_tree().create_timer(0.25).timeout       # wait for the bow draw
	var proj := Node2D.new()
	proj.position = position + Vector2(40, -55)
	get_parent().add_child(proj)
	if arrow_texture:
		var sp := Sprite2D.new()
		sp.texture = arrow_texture
		sp.scale = Vector2.ONE * 3.0
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		proj.add_child(sp)
	var tw := create_tween()
	tw.tween_property(proj, "position", target.position + Vector2(-10, -55), 0.2)
	await tw.finished
	proj.queue_free()

## Attack animation (fire-and-forget); no-op without sprites.
func _swing() -> void:
	if sprite:
		sprite.play(&"attack1")
		sprite.animation_finished.connect(func() -> void:
			if is_alive(): sprite.play(&"idle"), CONNECT_ONE_SHOT)

func _hop() -> void:
	if sprite:
		sprite.play(&"jump")
	var start := position
	var tw := create_tween()
	tw.tween_property(self, "position", start + Vector2(0, -50), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", start, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if sprite and is_alive():
		sprite.play(&"idle")
