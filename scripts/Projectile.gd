extends RigidBody2D

@export var impact_damage: int = 40
@export var explosion_radius: float = 60.0
@export var explosion_damage: int = 40

var wind_acceleration: float = 0.0
var _has_exploded: bool = false

const DESPAWN_LIMIT_X: float = 1200.0
const DESPAWN_LIMIT_Y: float = 800.0

signal exploded(position: Vector2, hit: Node, radius: float, radial_damage: int, impact_damage: int)

func _ready() -> void:
    contact_monitor = true
    max_contacts_reported = 4
    body_entered.connect(_on_body_entered)

func launch(initial_velocity: Vector2, wind_accel: float) -> void:
    wind_acceleration = wind_accel
    linear_velocity = initial_velocity

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    if wind_acceleration != 0.0:
        state.apply_central_force(Vector2(wind_acceleration * mass, 0.0))

func _physics_process(_delta: float) -> void:
    if _has_exploded:
        return
    if absf(global_position.x) > DESPAWN_LIMIT_X or absf(global_position.y) > DESPAWN_LIMIT_Y:
        _explode(null)

func _on_body_entered(body: Node) -> void:
    _explode(body)

func _explode(hit: Node) -> void:
    if _has_exploded:
        return
    _has_exploded = true
    emit_signal("exploded", global_position, hit, explosion_radius, explosion_damage, impact_damage)
    queue_free()
