extends SceneTree
func _init() -> void: run.call_deferred()
func run() -> void:
    root.unfocusable = true
    var game: Node = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    await create_timer(.2).timeout
    print("LAUNCHER_READY_AND_QUIT_SIGNAL")
    game.hud.secondary.pressed.emit()
