class_name ActionCommand
extends Node2D
## The "action command" timing mini-game (Mario & Luigi style).
## A ring shrinks toward a target circle; pressing the button when the ring
## matches the target gives a better rating. Used for BOTH attacking and
## countering, so the same code drives offense and defense.

enum Rating { MISS, GOOD, GREAT, PERFECT }

## Damage multiplier per rating (used by Fighter.calc_damage).
const MULTIPLIER := {
	Rating.MISS: 0.5,
	Rating.GOOD: 1.0,
	Rating.GREAT: 1.25,
	Rating.PERFECT: 1.5,
}
## Max distance (seconds) from the sweet spot for each rating.
const PERFECT_T := 0.05
const GREAT_T := 0.11
const GOOD_T := 0.22
const POPUP_TEXT := {Rating.MISS: "MISS...", Rating.GOOD: "GOOD!", Rating.GREAT: "GREAT!!", Rating.PERFECT: "PERFECT!!!"}
const POPUP_COLOR := {
	Rating.MISS: Color(0.9, 0.2, 0.2),        # red
	Rating.GOOD: Color(0.95, 0.95, 0.95),     # white
	Rating.GREAT: Color(0.4, 0.85, 1.0),      # sky blue
	Rating.PERFECT: Color(1.0, 0.82, 0.15),   # gold
}
const START_RADIUS := 64.0
const TARGET_RADIUS := 22.0

signal finished(rating: Rating)
signal started(input_action: StringName, sweet_spot: float)   # handy for UI / tests

var action: StringName = &""
var color := Color.WHITE
var duration := 0.6
var sweet_spot := 0.45
var _elapsed := 0.0
var _active := false
var last_rating: Rating = Rating.MISS
## quiet = no rating popup (used for the partner's assist window when only one hero is targeted).
var quiet := false
var key_label := ""          # letter shown inside the ring (e.g. "Z")

## Begin one timing window. Emits `finished` exactly once.
func start(input_action: StringName, win_duration: float = 0.6, ring_color: Color = Color.WHITE, silent: bool = false) -> void:
	quiet = silent
	key_label = ""
	for ev in InputMap.action_get_events(input_action):
		if ev is InputEventKey:
			key_label = OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)
			break
	action = input_action
	duration = win_duration
	sweet_spot = win_duration * 0.75
	color = ring_color
	_elapsed = 0.0
	_active = true
	visible = true
	set_process(true)
	started.emit(action, sweet_spot)

## Convenience: start a window and wait for the result.
func run(input_action: StringName, win_duration: float = 0.6, ring_color: Color = Color.WHITE) -> Rating:
	start(input_action, win_duration, ring_color)
	return await finished

func _ready() -> void:
	visible = false
	set_process(false)
	z_index = 10

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	queue_redraw()
	# Window expired without a press -> miss.
	if _elapsed > sweet_spot + GOOD_T:
		_end(Rating.MISS)

func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed(action):
		get_viewport().set_input_as_handled()
		var diff := absf(_elapsed - sweet_spot)
		var r := Rating.MISS
		if diff <= PERFECT_T:
			r = Rating.PERFECT
		elif diff <= GREAT_T:
			r = Rating.GREAT
		elif diff <= GOOD_T:
			r = Rating.GOOD
		_end(r)

func _end(r: Rating) -> void:
	_active = false
	last_rating = r
	set_process(false)
	# Brief feedback flash, then hide.
	queue_redraw()
	_show_popup(r)
	finished.emit(r)
	await get_tree().create_timer(0.15).timeout
	if not _active:
		visible = false

func _draw() -> void:
	if not _active:
		return
	var t := clampf(_elapsed / sweet_spot, 0.0, 1.0)
	var radius := lerpf(START_RADIUS, TARGET_RADIUS, t)
	draw_circle(Vector2.ZERO, TARGET_RADIUS, Color(0, 0, 0, 0.55))
	draw_arc(Vector2.ZERO, TARGET_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.9), 3.0)
	if key_label != "":
		var f := PopupText.get_font()
		draw_string(f, Vector2(-TARGET_RADIUS, 10), key_label, HORIZONTAL_ALIGNMENT_CENTER, TARGET_RADIUS * 2.0, 32, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, 4.0)

## Floating rating text ("PERFECT!!!") - see PopupText.
func _show_popup(r: Rating) -> void:
	if quiet:
		return
	PopupText.spawn(self, Vector2(0, -30), POPUP_TEXT[r], POPUP_COLOR[r], 32 if r < Rating.GREAT else 48, 50.0)
