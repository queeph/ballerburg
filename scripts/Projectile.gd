extends RigidBody2D

var wind_acceleration: float = 0.0
var damage: int = 40

signal exploded(position: Vector2, hit: Node)

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func launch(initial_velocity: Vector2, wind_accel: float) -> void:
    wind_acceleration = wind_accel
    linear_velocity = initial_velocity

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    if wind_acceleration != 0.0:
        state.apply_central_force(Vector2(wind_acceleration * mass, 0.0))

func _on_body_entered(body: Node) -> void:
    emit_signal("exploded", global_position, body)
    queue_free()

func _on_area_entered(area: Area2D) -> void:
    emit_signal("exploded", global_position, area)
    queue_free()
