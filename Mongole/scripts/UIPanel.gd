extends CanvasLayer
class_name UIPanel
# UIPanel.gd — HUD: resource bar at the top + game-over overlay.
# Drawn on a CanvasLayer so it always renders above the hex grid.

var lbl_food:   Label
var lbl_horses: Label
var lbl_gold:   Label
var lbl_turn:   Label
var lbl_tiles:  Label
var lbl_status: Label
var btn_end:    Button

# ── Lifecycle ──────────────────────────────────────────────

func _ready() -> void:
	_build_hud()
	GameState.resources_changed.connect(_on_resources_changed)
	GameState.turn_changed.connect(_on_turn_changed)
	refresh()

func _on_resources_changed() -> void:
	refresh()

# ── Build the HUD bar ──────────────────────────────────────

func _build_hud() -> void:
	# Dark top bar
	var bar = Panel.new()
	bar.position = Vector2(0, 0)
	bar.size     = Vector2(1280, 78)
	var style = StyleBoxFlat.new()
	style.bg_color            = Color(0.08, 0.05, 0.03, 0.95)
	style.border_color        = Color(0.68, 0.53, 0.30)
	style.border_width_bottom = 2
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)

	# Title
	var title = Label.new()
	title.text     = "⚔  Mongol Khan"
	title.position = Vector2(14, 16)
	_sl(title, 22, Color(1.00, 0.80, 0.45))
	bar.add_child(title)

	# Resource labels
	lbl_food   = _lbl(bar, "🌾  Food: 0",   Vector2(220, 20))
	lbl_horses = _lbl(bar, "🐴  Horses: 0", Vector2(375, 20))
	lbl_gold   = _lbl(bar, "🪙  Gold: 0",   Vector2(530, 20))
	lbl_turn   = _lbl(bar, "Turn 1 / 20",   Vector2(685, 20))
	lbl_tiles  = _lbl(bar, "Territory: 0%", Vector2(820, 20))
	lbl_status = _lbl(bar, "Your turn",     Vector2(995, 20))
	lbl_status.add_theme_color_override("font_color", Color(0.50, 1.00, 0.50))

	# End Turn button
	btn_end          = Button.new()
	btn_end.text     = "End Turn  →"
	btn_end.position = Vector2(1110, 16)
	btn_end.size     = Vector2(152,  46)
	var bs = StyleBoxFlat.new()
	bs.bg_color     = Color(0.50, 0.27, 0.06)
	bs.border_color = Color(0.87, 0.65, 0.24)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(6)
	btn_end.add_theme_stylebox_override("normal", bs)
	bar.add_child(btn_end)

# ── Helper: create a styled label ─────────────────────────

func _lbl(parent: Node, text: String, pos: Vector2) -> Label:
	var l = Label.new()
	l.text     = text
	l.position = pos
	_sl(l, 16, Color(0.88, 0.82, 0.70))
	parent.add_child(l)
	return l

func _sl(lbl: Label, size: int, color: Color) -> void:
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color",   color)

# ── Refresh labels from GameState ─────────────────────────

func refresh() -> void:
	lbl_food.text   = "🌾  Food: %d"   % GameState.food
	lbl_horses.text = "🐴  Horses: %d" % GameState.horses
	lbl_gold.text   = "🪙  Gold: %d"   % GameState.gold
	lbl_turn.text   = "Turn %d / %d"   % [GameState.current_turn, GameState.MAX_TURNS]

func set_tile_percent(pct: int) -> void:
	lbl_tiles.text = "Territory: %d%%" % pct

# ── Turn-change signal handler ─────────────────────────────

func _on_turn_changed(turn: int, is_player: bool) -> void:
	refresh()
	if is_player:
		lbl_status.text = "Your turn"
		lbl_status.add_theme_color_override("font_color", Color(0.50, 1.00, 0.50))
		btn_end.disabled = false
	else:
		lbl_status.text = "AI moving…"
		lbl_status.add_theme_color_override("font_color", Color(1.00, 0.50, 0.50))
		btn_end.disabled = true

# ── Game-over overlay ──────────────────────────────────────

func show_game_over(message: String) -> void:
	btn_end.disabled = true
	lbl_status.text  = "GAME OVER"
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))

	# Dim overlay
	var overlay = ColorRect.new()
	overlay.color    = Color(0.0, 0.0, 0.0, 0.72)
	overlay.position = Vector2(0, 0)
	overlay.size     = Vector2(1280, 720)
	add_child(overlay)

	# Message box
	var box = Panel.new()
	box.position = Vector2(340, 235)
	box.size     = Vector2(600, 230)
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color     = Color(0.10, 0.06, 0.03, 0.97)
	bstyle.border_color = Color(0.87, 0.65, 0.24)
	bstyle.set_border_width_all(3)
	bstyle.set_corner_radius_all(12)
	box.add_theme_stylebox_override("panel", bstyle)
	add_child(box)

	var msg = Label.new()
	msg.text               = message + "\n\nReopen the project to play again."
	msg.position           = Vector2(40, 55)
	msg.size               = Vector2(520, 130)
	msg.autowrap_mode      = TextServer.AUTOWRAP_WORD
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sl(msg, 26, Color(1.0, 0.85, 0.50))
	box.add_child(msg)
