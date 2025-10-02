extends Node2D

@export_range(0.0, 60.0, 1.0) var wind_max_strength: float = 20.0
@export var projectile_scene: PackedScene
@export var base_damage: int = 40


enum Player { LEFT, RIGHT }

@onready var castle_left: Castle = $CastleLeft
@onready var castle_right: Castle = $CastleRight
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var turn_label: Label = $HUD/Control/VBoxContainer/TurnLabel
@onready var wind_label: Label = $HUD/Control/VBoxContainer/WindLabel
@onready var angle_label: Label = $HUD/Control/VBoxContainer/AngleContainer/AngleLabel
@onready var angle_dial: AngleDial = $HUD/Control/VBoxContainer/AngleContainer/AngleDial
@onready var power_label: Label = $HUD/Control/VBoxContainer/PowerContainer/PowerLabel
@onready var power_slider: HSlider = $HUD/Control/VBoxContainer/PowerContainer/PowerSlider
@onready var fire_button: Button = $HUD/Control/VBoxContainer/FireButton
@onready var info_label: Label = $HUD/Control/VBoxContainer/InfoLabel

var current_player: Player = Player.LEFT
var wind_strength: float = 0.0
var _round: int = 1
var _rng := RandomNumberGenerator.new()
var _active_projectile: RigidBody2D = null
const POWER_TO_SPEED: float = 8.0 # Map slider input (m/s) to engine speed units

func _ready() -> void:
	_rng.randomize()
	fire_button.pressed.connect(_on_fire_button_pressed)
	angle_dial.value_changed.connect(_update_angle_label)
	power_slider.value_changed.connect(_update_power_label)
	castle_left.destroyed.connect(_on_castle_destroyed)
	castle_right.destroyed.connect(_on_castle_destroyed)
	castle_left.section_detonated.connect(_on_section_detonated)
	castle_right.section_detonated.connect(_on_section_detonated)
	_update_angle_label(angle_dial.value)
	_update_power_label(power_slider.value)
	start_match()

func start_match() -> void:
	_round = 1
	current_player = Player.LEFT
	_reset_castles()
	_roll_wind()
	_update_ui()
	info_label.text = ""

func _reset_castles() -> void:
	castle_left.reset_health()
	castle_right.reset_health()

func _roll_wind() -> void:
	wind_strength = _rng.randf_range(-wind_max_strength, wind_max_strength)

func _update_ui() -> void:
	turn_label.text = "%s ist am Zug (Runde %d)" % [_get_active_castle().castle_name, _round]
	var direction := "→" if wind_strength > 0.1 else ("←" if wind_strength < -0.1 else "·")
	wind_label.text = "Wind: %s %.1f" % [direction, absf(wind_strength)]
	fire_button.disabled = _active_projectile != null

func _on_fire_button_pressed() -> void:
	if projectile_scene == null or _active_projectile != null:
		return
	var angle_deg := angle_dial.value
	var power := power_slider.value
	var castle := _get_active_castle()
	var horizontal_offset := 60 if current_player == Player.LEFT else -60
	var origin := castle.global_position + Vector2(horizontal_offset, -60)
	var angle_rad := deg_to_rad(angle_deg)
	var direction := Vector2(cos(angle_rad), -sin(angle_rad))
	if current_player == Player.RIGHT:
		direction.x *= -1
	var velocity := direction * power * POWER_TO_SPEED
	var projectile := projectile_scene.instantiate() as RigidBody2D
	projectile.global_position = origin
	projectile.launch(velocity, wind_strength)
	projectile.impact_damage = base_damage
	projectile.explosion_damage = base_damage
	projectile.explosion_radius = 72.0
	projectile.exploded.connect(_on_projectile_exploded)
	projectile_layer.add_child(projectile)
	_active_projectile = projectile
	fire_button.disabled = true
	info_label.text = "Geschoss unterwegs …"



func _on_projectile_exploded(impact_position: Vector2, hit: Node, radius: float, radial_damage: int, impact_damage: int) -> void:
	_active_projectile = null
	var handled := false
	var section := _find_parent_section(hit)
	if section != null:
		section.apply_damage(impact_damage)
		if section.current_health <= 0:
			info_label.text = "%s zerstört %s" % [_get_active_player_name(current_player), section.section_name]
		else:
			info_label.text = "%s trifft %s" % [_get_active_player_name(current_player), section.section_name]
		handled = true
	else:
		var castle := _find_parent_castle(hit)
		if castle != null:
			castle.take_damage(impact_damage)
			info_label.text = "%s trifft %s" % [_get_active_player_name(current_player), castle.castle_name]
			handled = true
	if not handled:
		info_label.text = "Einschlag bei (%.0f | %.0f)" % [impact_position.x, impact_position.y]
	_apply_area_damage(impact_position, radius, radial_damage)
	if _check_victory():
		return
	_advance_turn()

func _advance_turn() -> void:
	current_player = Player.RIGHT if current_player == Player.LEFT else Player.LEFT
	if current_player == Player.LEFT:
		_round += 1
		_roll_wind()
	_update_ui()

func _find_parent_castle(node: Node) -> Castle:
	var current := node
	while current:
		if current is Castle:
			return current as Castle
		current = current.get_parent()
	return null

func _find_parent_section(node: Node) -> Section:
	var current := node
	while current:
		if current is Section:
			return current as Section
		current = current.get_parent()
	return null

func _apply_area_damage(center: Vector2, radius: float, damage: int) -> void:
	if radius <= 0.0 or damage <= 0:
		return
	castle_left.apply_area_damage(center, radius, damage)
	castle_right.apply_area_damage(center, radius, damage)

func _on_section_detonated(center: Vector2, radius: float, damage: int) -> void:
	_apply_area_damage(center, radius, damage)
	info_label.text = "Sekundärexplosion!"
	_check_victory()

func _check_victory() -> bool:
	if castle_left.current_health <= 0:
		_declare_winner(castle_right.castle_name)
		return true
	if castle_right.current_health <= 0:
		_declare_winner(castle_left.castle_name)
		return true
	return false

func _declare_winner(winner_name: String) -> void:
	info_label.text = "%s gewinnt!" % winner_name
	fire_button.disabled = true

func _get_active_castle() -> Castle:
	return castle_left if current_player == Player.LEFT else castle_right

func _get_active_player_name(player: Player) -> String:
	return castle_left.castle_name if player == Player.LEFT else castle_right.castle_name

func _on_castle_destroyed(castle_name: String) -> void:
	_declare_winner(castle_name)

func _update_angle_label(value: float) -> void:
	angle_label.text = "Winkel: %d°" % int(round(value))

func _update_power_label(value: float) -> void:
	power_label.text = "Stärke: %d m/s" % int(round(value))
