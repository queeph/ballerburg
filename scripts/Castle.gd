class_name Castle
extends Node2D

@export var castle_name: String = "Player"
@export var max_health: int = 100
@export var section_count: int = 3

signal health_changed(current: int, max: int)
signal destroyed(castle_name: String)

var current_health: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
    current_health = max_health
    name_label.text = castle_name
    _update_health_ui()

func take_damage(amount: int) -> void:
    current_health = clamp(current_health - amount, 0, max_health)
    _update_health_ui()
    emit_signal("health_changed", current_health, max_health)
    if current_health == 0:
        emit_signal("destroyed", castle_name)
        sprite.modulate = Color(0.3, 0.3, 0.3)

func reset_health() -> void:
    current_health = max_health
    sprite.modulate = Color.WHITE
    _update_health_ui()

func _update_health_ui() -> void:
    health_label.text = "HP: %d" % current_health
