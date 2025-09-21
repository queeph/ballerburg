class_name AngleDial
extends Control

signal value_changed(value: float)

@export var min_value: float = -10.0:
    set(value):
        min_value = value
        if max_value < min_value:
            max_value = min_value
        _clamp_value(false)

@export var max_value: float = 80.0:
    set(value):
        max_value = value
        if max_value < min_value:
            min_value = max_value
        _clamp_value(false)

@export var step: float = 1.0:
    set(value):
        step = max(value, 0.0001)
        _clamp_value(false)

@export var start_angle_deg: float = -135.0:
    set(value):
        start_angle_deg = value
        queue_redraw()

@export var end_angle_deg: float = 135.0:
    set(value):
        end_angle_deg = value
        queue_redraw()

@export var knob_color: Color = Color(0.2, 0.2, 0.2)
@export var groove_color: Color = Color(0.08, 0.08, 0.08)
@export var pointer_color: Color = Color(0.85, 0.85, 0.85)

var _value: float = 0.0

@export var value: float = 0.0:
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

func _set_value_internal(new_value: float, emit_signal: bool) -> void:
    var snapped := snappedf(new_value, step)
    var clamped := clampf(snapped, min_value, max_value)
    if not is_equal_approx(_value, clamped):
        _value = clamped
        queue_redraw()
        if emit_signal and is_inside_tree():
            value_changed.emit(_value)
    elif emit_signal and is_inside_tree():
        value_changed.emit(_value)

func _clamp_value(emit_signal: bool) -> void:
    _set_value_internal(_value, emit_signal)

func _draw_dial() -> void:
    var radius := min(size.x, size.y) * 0.5 - 2.0
    if radius <= 0.0:
        return
    var center := size * 0.5
    draw_circle(center, radius, groove_color)
    draw_circle(center, radius * 0.85, knob_color)

    var angle := _value_to_angle(_value)
    var pointer_length := radius * 0.7
    var pointer_start := center
    var pointer_end := center + Vector2.RIGHT.rotated(angle) * pointer_length
    draw_line(pointer_start, pointer_end, pointer_color, 4.0, true)
    draw_circle(center, radius * 0.1, pointer_color)

    var tick_radius := radius * 0.95
    var tick_inner := radius * 0.8
    var tick_count := 6
    if tick_count > 1:
        var tick_color := pointer_color.with_alpha(0.4)
        for i in range(tick_count):
            var t := float(i) / float(tick_count - 1)
            var tick_angle := lerp(_deg_to_rad(start_angle_deg), _deg_to_rad(end_angle_deg), t)
            var outer := center + Vector2.RIGHT.rotated(tick_angle) * tick_radius
            var inner := center + Vector2.RIGHT.rotated(tick_angle) * tick_inner
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
    var center := size * 0.5
    var offset := pos - center
    if offset.length() < 1.0:
        return
    var angle := atan2(-offset.y, offset.x)
    var start_angle := _deg_to_rad(start_angle_deg)
    var end_angle := _deg_to_rad(end_angle_deg)
    if end_angle < start_angle:
        var tmp := start_angle
        start_angle = end_angle
        end_angle = tmp
    angle = clampf(angle, start_angle, end_angle)
    var t := (angle - start_angle) / max((end_angle - start_angle), 0.00001)
    var value_span := max_value - min_value
    var new_value := min_value + t * value_span
    _set_value_internal(new_value, true)

func _value_to_angle(current_value: float) -> float:
    var value_span := max_value - min_value
    if is_equal_approx(value_span, 0.0):
        return _deg_to_rad(start_angle_deg)
    var t := (current_value - min_value) / value_span
    return _deg_to_rad(start_angle_deg + t * (end_angle_deg - start_angle_deg))

func _deg_to_rad(deg: float) -> float:
    return deg2rad(deg)
