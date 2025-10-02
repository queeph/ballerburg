class_name Castle
extends Node2D

@export var castle_name: String = "Player"
@export var max_health: int = 100
@export var section_count: int = 3

signal health_changed(current: int, max: int)
signal destroyed(castle_name: String)
signal section_detonated(center: Vector2, radius: float, damage: int)

var current_health: int
var _sections: Array[Section] = []
var _is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	name_label.text = castle_name
	_gather_sections()
	_update_health_ui()

func take_damage(amount: int) -> void:
	if _sections.is_empty():
		_apply_direct_health_damage(amount)
		return
	var target := _get_priority_section()
	if target:
		target.apply_damage(amount)

func reset_health() -> void:
	if _sections.is_empty():
		current_health = max_health
	else:
		for section in _sections:
			section.reset_section()
		current_health = _calculate_total_health()
	sprite.modulate = Color.WHITE
	_is_destroyed = false
	_update_health_ui()

func _update_health_ui() -> void:
	health_label.text = "HP: %d" % current_health
	emit_signal("health_changed", current_health, max_health)

func apply_area_damage(center: Vector2, radius: float, damage: int) -> void:
	for section in _sections:
		section.apply_explosion(center, radius, damage)

func apply_direct_section_damage(section: Section, damage: int) -> void:
	if section and section in _sections:
		section.apply_damage(damage)

func _gather_sections() -> void:
	_sections.clear()
	var total_health := 0
	for child in get_children():
		if child is Section:
			var section := child as Section
			_sections.append(section)
			total_health += section.max_health
			section.health_changed.connect(_on_section_health_changed)
			section.destroyed.connect(_on_section_destroyed)
			section.detonated.connect(_on_section_detonated)
			section.victory_triggered.connect(_on_section_victory)
	if total_health > 0:
		max_health = total_health
		current_health = _calculate_total_health()
	else:
		current_health = max_health
	_is_destroyed = current_health <= 0

func _calculate_total_health() -> int:
	var total := 0
	for section in _sections:
		total += section.current_health
	return total

func _apply_direct_health_damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	_update_health_ui()
	if current_health == 0:
		_mark_destroyed()

func _get_priority_section() -> Section:
	var preferred := ["tower", "keep", "king"]
	for type in preferred:
		for section in _sections:
			if section.section_type == type and section.current_health > 0:
				return section
	for section in _sections:
		if section.current_health > 0:
			return section
	return null

func _on_section_health_changed(section: Section, _current: int, _max: int) -> void:
	current_health = _calculate_total_health()
	if current_health <= 0:
		_mark_destroyed()
	_update_health_ui()

func _on_section_destroyed(section: Section) -> void:
	current_health = _calculate_total_health()
	_update_health_ui()

func _on_section_detonated(_section: Section, center: Vector2, radius: float, damage: int) -> void:
	section_detonated.emit(center, radius, damage)

func _on_section_victory(_section: Section) -> void:
	_mark_destroyed()

func _mark_destroyed() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	sprite.modulate = Color(0.3, 0.3, 0.3)
	emit_signal("destroyed", castle_name)
