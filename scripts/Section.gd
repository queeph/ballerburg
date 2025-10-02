class_name Section
extends Node2D

@export var section_name: String = "Section"
@export_enum("wall", "keep", "tower", "powder", "king") var section_type: String = "wall"
@export var max_health: int = 40
@export var explosion_radius: float = 0.0
@export var explosion_damage: int = 0

signal health_changed(section: Section, current: int, max: int)
signal destroyed(section: Section)
signal detonated(section: Section, center: Vector2, radius: float, damage: int)
signal victory_triggered(section: Section)

var current_health: int
var _destroyed: bool = false
var _collision_shapes: Array[CollisionShape2D] = []
var _visual_items: Array[CanvasItem] = []

func _ready() -> void:
	current_health = max(1, max_health)
	_gather_children()
	_set_visual_state(true)

func reset_section() -> void:
	_destroyed = false
	current_health = max_health
	for shape in _collision_shapes:
		shape.disabled = false
	_set_visual_state(true)
	health_changed.emit(self, current_health, max_health)

func apply_damage(amount: int) -> void:
	if _destroyed:
		return
	var effective := int(round(amount * _damage_multiplier()))
	if effective <= 0:
		effective = 1
	current_health = max(0, current_health - effective)
	health_changed.emit(self, current_health, max_health)
	if current_health == 0:
		_handle_destruction()

func apply_explosion(center: Vector2, radius: float, base_damage: int) -> void:
	if _destroyed or radius <= 0.0:
		return
	var distance := global_position.distance_to(center)
	if distance > radius:
		return
	var falloff: float = 1.0 - clamp(distance / radius, 0.0, 1.0)
	var damage := int(round(max(0.0, base_damage * falloff)))
	if damage > 0:
		apply_damage(damage)

func _handle_destruction() -> void:
	_destroyed = true
	for shape in _collision_shapes:
		shape.disabled = true
	_set_visual_state(false)
	destroyed.emit(self)
	if section_type == "powder":
		var radius := explosion_radius if explosion_radius > 0.0 else 160.0
		var damage := explosion_damage if explosion_damage > 0 else int(max_health * 2)
		detonated.emit(self, global_position, radius, damage)
	elif explosion_radius > 0.0:
		var damage := explosion_damage if explosion_damage > 0 else max_health
		detonated.emit(self, global_position, explosion_radius, damage)
	if section_type == "king":
		victory_triggered.emit(self)

func _damage_multiplier() -> float:
	match section_type:
		"wall":
			return 1.0
		"keep":
			return 0.8
		"tower":
			return 0.6
		"powder":
			return 1.2
		"king":
			return 0.7
		_:
			return 1.0

func _gather_children() -> void:
	_collision_shapes.clear()
	_visual_items.clear()
	var shapes := find_children("", "CollisionShape2D", true, false)
	for item in shapes:
		if item is CollisionShape2D:
			_collision_shapes.append(item)
	var visuals := find_children("", "CanvasItem", true, false)
	for item in visuals:
		if item is CanvasItem:
			_visual_items.append(item)

func _set_visual_state(visible_state: bool) -> void:
	visible = visible_state
	for item in _visual_items:
		item.visible = visible_state
