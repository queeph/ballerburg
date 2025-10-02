class_name AngleDial
extends Control

signal value_changed(value: float)

var _value: float = 0.0

@export var min_value: float = -10.0
@export var max_value: float = 80.0
@export var step: float = 1.0
@export var start_angle_deg: float = 90.0
@export var end_angle_deg: float = -90.0
@export var knob_color: Color = Color(0.2, 0.2, 0.2)
@export var groove_color: Color = Color(0.08, 0.08, 0.08)
@export var pointer_color: Color = Color(0.85, 0.85, 0.85)
@export var value: float = 45.0:
	set(new_value):
		_set_value_internal(new_value, true)
	get:
		return _value

func _ready() -> void:
	focus_mode = FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clamp_value(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_draw_dial()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_value(new_value: float) -> void:
	_set_value_internal(new_value, true)

func _set_value_internal(new_value: float, propagate: bool) -> void:
	var min_v: float = min(min_value, max_value)
	var max_v: float = max(min_value, max_value)
	var step_v: float = step if step > 0.0 else 0.0001
	var snapped_value: float = snappedf(new_value, step_v)
	var clamped_value: float = clampf(snapped_value, min_v, max_v)
	if not is_equal_approx(_value, clamped_value):
		_value = clamped_value
		queue_redraw()
		if propagate and is_inside_tree():
			value_changed.emit(_value)
	elif propagate and is_inside_tree():
		value_changed.emit(_value)

func _clamp_value(propagate: bool) -> void:
	_set_value_internal(_value, propagate)

func _draw_dial() -> void:
	var radius: float = min(size.x, size.y) * 0.5 - 2.0
	if radius <= 0.0:
		return
	var center: Vector2 = size * 0.5
	draw_circle(center, radius, groove_color)
	draw_circle(center, radius * 0.85, knob_color)
	var angle: float = _value_to_angle(_value)
	var pointer_length: float = radius * 0.7
	var pointer_end: Vector2 = center + Vector2.RIGHT.rotated(angle) * pointer_length
	draw_line(center, pointer_end, pointer_color, 4.0, true)
	draw_circle(center, radius * 0.1, pointer_color)
	var tick_radius: float = radius * 0.95
	var tick_inner: float = radius * 0.8
	var tick_count: int = 6
	if tick_count > 1:
		var tick_color: Color = pointer_color * Color(1, 1, 1, 0.4)
		for i in range(tick_count):
			var t: float = float(i) / float(tick_count - 1)
			var tick_angle: float = lerp_angle_deg(start_angle_deg, end_angle_deg, t)
			var outer: Vector2 = center + Vector2.RIGHT.rotated(deg_to_rad(tick_angle)) * tick_radius
			var inner: Vector2 = center + Vector2.RIGHT.rotated(deg_to_rad(tick_angle)) * tick_inner
			draw_line(inner, outer, tick_color, 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_value_from_position(event.position)
			accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_value_from_position(event.position)
		accept_event()


func _update_value_from_position(pos: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var vector: Vector2 = pos - center
	if vector.length() < 1.0:
		return
	var angle_deg: float = rad_to_deg(atan2(vector.y, vector.x))
	var min_angle: float = min(start_angle_deg, end_angle_deg)
	var max_angle: float = max(start_angle_deg, end_angle_deg)
	angle_deg = clampf(angle_deg, min_angle, max_angle)
	var span_deg: float = end_angle_deg - start_angle_deg
	if is_zero_approx(span_deg):
		return
	var t: float = (angle_deg - start_angle_deg) / span_deg
	t = clampf(t, 0.0, 1.0)
	var min_v: float = min(min_value, max_value)
	var max_v: float = max(min_value, max_value)
	var new_value: float = lerp(min_v, max_v, t)
	_set_value_internal(new_value, true)
func _value_to_angle(current_value: float) -> float:
	var min_v: float = min(min_value, max_value)
	var max_v: float = max(min_value, max_value)
	var value_span: float = max_v - min_v
	if is_zero_approx(value_span):
		return deg_to_rad(start_angle_deg)
	var t: float = (current_value - min_v) / value_span
	t = clampf(t, 0.0, 1.0)
	var angle: float = start_angle_deg + t * (end_angle_deg - start_angle_deg)
	return deg_to_rad(angle)

func lerp_angle_deg(a: float, b: float, weight: float) -> float:
	return a + (b - a) * weight
