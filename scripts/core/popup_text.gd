class_name PopupText
extends RefCounted
## Floating pixel-font text (damage numbers, ratings). One static call:
##   PopupText.spawn(parent_node, local_position, "123", Color.WHITE, 32)

const FONT_PATH := "res://assets/fonts/PeaberryBase.ttf"   # Peaberry (OFL)
static var _font: FontFile

static func get_font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH)
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE      # keep pixels crisp
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font

## size should be a multiple of 16 (the font's pixel grid): 16, 32, 48...
static func spawn(parent: Node, pos: Vector2, text: String, color: Color, size: int = 32, rise: float = 40.0) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", get_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.z_index = 20
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.position = pos - l.size / 2.0
	l.scale = Vector2.ONE * 0.4
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - rise, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)
