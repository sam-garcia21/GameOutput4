class_name Fighter
extends Node2D
## Shared base for every combatant (heroes AND enemies).
## Teammates: extend this for enemies so the battle handler can treat
## everyone the same way (take_damage / heal / is_alive / signals).

signal log_message(text: String)          # feed this into the UI text box
signal hp_changed(who: Fighter, current: int, maximum: int)
signal damaged(amount: int, attacker: Fighter)
signal died(who: Fighter)

@export var fighter_name := "Fighter"
@export var max_hp := 100
@export var atk := 20
@export var def := 5
@export var spd := 10                      # for the battle handler's turn order
@export var body_color := Color(0.8, 0.8, 0.8)
@export var texture: Texture2D             # optional sprite; falls back to a box

var hp := 0
var home_position := Vector2.ZERO
@export var head_offset := Vector2(0, -130)   # where damage numbers appear
var _flash := 0.0
var sprite: AnimatedSprite2D               # set by setup_sprites(); null = box art
var is_defending: bool = false

## Build an AnimatedSprite2D from horizontal sprite sheets.
## anims: {name: [png_path, frame_count, fps, loop]}. Frames are square
## (side = sheet height). `feet` = pixel in a frame that should sit on this
## node's origin, so animations line up with the ground.
func setup_sprites(anims: Dictionary, feet: Vector2, sprite_scale: float) -> void:
	sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var side := 0
	for anim_name in anims:
		var a: Array = anims[anim_name]
		var tex: Texture2D = load(a[0])
		side = tex.get_height()
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, a[2])
		frames.set_animation_loop(anim_name, a[3])
		for i in a[1]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * side, 0, side, side)
			frames.add_frame(anim_name, at)
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.position = Vector2(side / 2.0 - feet.x, side / 2.0 - feet.y) * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.play("idle")

## Play a one-shot animation, then return to idle (waits for it to finish).
func play_once(anim: StringName) -> void:
	if sprite == null or not sprite.sprite_frames.has_animation(anim):
		return
	sprite.play(anim)
	await sprite.animation_finished
	if is_alive():
		sprite.play("idle")

func _on_hit_visual() -> void:
	if sprite and is_alive() and sprite.animation != &"attack1":
		play_once(&"hit")

func _ready() -> void:
	hp = max_hp
	home_position = position

func is_alive() -> bool:
	return hp > 0

## ---- RNG damage formula (shared so everyone's numbers feel consistent) ----
## Returns {damage:int, crit:bool, missed:bool}
func calc_damage(power: float, rating: int, target: Fighter) -> Dictionary:
	var result := {"damage": 0, "crit": false, "missed": false}
	if randf() < 0.05:                                   # 5% whiff
		result.missed = true
		return result
	var raw := atk * power / 100.0
	raw *= ActionCommand.MULTIPLIER[rating]
	raw *= randf_range(0.9, 1.1)                         # high/low damage roll
	var crit_chance := 0.08 + (0.25 if rating == ActionCommand.Rating.PERFECT else 0.0)
	if randf() < crit_chance:
		raw *= 1.5
		result.crit = true
	result.damage = maxi(1, int(round(raw - target.def * 0.5)))
	return result

## Applies damage and returns the amount actually lost.
func take_damage(amount: int, attacker: Fighter = null) -> int:
	if not is_alive():
		return 0
	if (is_defending):
		amount /= 2
	var lost := mini(amount, hp)
	hp -= lost
	_flash = 0.25
	queue_redraw()
	_on_hit_visual()
	PopupText.spawn(self, head_offset, str(lost), Color.WHITE, 32)
	hp_changed.emit(self, hp, max_hp)
	damaged.emit(lost, attacker)
	if hp <= 0:
		log_message.emit("%s was defeated!" % fighter_name)
		if sprite and sprite.sprite_frames.has_animation(&"death"):
			sprite.play(&"death")
		died.emit(self)
	return lost

func heal(amount: int) -> int:
	if not is_alive():
		return 0
	var gained := mini(amount, max_hp - hp)
	hp += gained
	PopupText.spawn(self, head_offset, "+%d" % gained, Color(0.4, 1, 0.5), 32)
	hp_changed.emit(self, hp, max_hp)
	return gained
	
func defend():
	is_defending = true
	
func start_turn():
	if is_defending:
		is_defending = false

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()

## Placeholder art: swap by assigning `texture`.
func _draw() -> void:
	var col := body_color
	if not is_alive():
		col = col.darkened(0.6)
		col.a = 0.5
	elif _flash > 0.0:
		col = Color.WHITE
	if sprite:
		return
	if texture:
		draw_texture(texture, -texture.get_size() / 2.0, col if _flash > 0.0 else Color.WHITE)
	else:
		draw_rect(Rect2(-20, -64, 40, 64), col)
		draw_rect(Rect2(-12, -56, 8, 8), Color.BLACK)
		draw_rect(Rect2(4, -56, 8, 8), Color.BLACK)
