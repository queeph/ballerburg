extends Node2D

@export_range(0.0, 60.0, 1.0) var wind_max_strength: float = 20.0
@export var projectile_scene: PackedScene
@export var base_damage: int = 40

const GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum Player { LEFT, RIGHT }

@onready var castle_left: Castle = $CastleLeft
@onready var castle_right: Castle = $CastleRight
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var turn_label: Label = $HUD/Control/VBoxContainer/TurnLabel
@onready var wind_label: Label = $HUD/Control/VBoxContainer/WindLabel
@onready var angle_box: SpinBox = $HUD/Control/VBoxContainer/AngleBox
@onready var power_box: SpinBox = $HUD/Control/VBoxContainer/PowerBox
@onready var fire_button: Button = $HUD/Control/VBoxContainer/FireButton
@onready var info_label: Label = $HUD/Control/VBoxContainer/InfoLabel

var current_player: Player = Player.LEFT
var wind_strength: float = 0.0
var _round: int = 1
var _rng := RandomNumberGenerator.new()
var _active_projectile: RigidBody2D = null

func _ready() -> void:
    _rng.randomize()
    fire_button.pressed.connect(_on_fire_button_pressed)
    castle_left.destroyed.connect(_on_castle_destroyed)
    castle_right.destroyed.connect(_on_castle_destroyed)
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
    var angle_deg := angle_box.value
    var power := power_box.value
    var castle := _get_active_castle()
    var origin := castle.global_position + Vector2(current_player == Player.LEFT ? 60 : -60, -60)
    var angle_rad := deg_to_rad(angle_deg)
    var direction := Vector2(cos(angle_rad), -sin(angle_rad))
    if current_player == Player.RIGHT:
        direction.x *= -1
    var velocity := direction * power
    var projectile := projectile_scene.instantiate() as RigidBody2D
    projectile.global_position = origin
    projectile.launch(velocity, wind_strength)
    projectile.exploded.connect(_on_projectile_exploded)
    projectile_layer.add_child(projectile)
    _active_projectile = projectile
    fire_button.disabled = true
    info_label.text = "Geschoss unterwegs …"

func _on_projectile_exploded(position: Vector2, hit: Node) -> void:
    _active_projectile = null
    _process_hit(hit, position)
    if _check_victory():
        return
    _advance_turn()

func _process_hit(hit: Node, impact_position: Vector2) -> void:
    var castle := _find_parent_castle(hit)
    if castle != null:
        castle.take_damage(base_damage)
        info_label.text = "%s trifft %s" % [_get_active_player_name(current_player), castle.castle_name]
    else:
        info_label.text = "Einschlag bei (%.0f | %.0f)" % [impact_position.x, impact_position.y]

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
