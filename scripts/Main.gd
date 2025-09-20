extends Node

@export var game_world_scene: PackedScene

var _game_world_instance: Node = null

func _ready() -> void:
    if game_world_scene:
        _spawn_game_world()
    else:
        push_warning("Game world scene not assigned.")

func _spawn_game_world() -> void:
    if _game_world_instance:
        _game_world_instance.queue_free()
    if game_world_scene == null:
        return
    _game_world_instance = game_world_scene.instantiate()
    add_child(_game_world_instance)
    move_child(_game_world_instance, 0)

func reload_match() -> void:
    _spawn_game_world()
