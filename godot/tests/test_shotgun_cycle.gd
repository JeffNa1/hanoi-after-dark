extends SceneTree
var failures: Array = []
func _init() -> void: _run.call_deferred()
func _run() -> void:
    var game: Node = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    game.start_run()
    for enemy in game.enemies: enemy.set_physics_process(false)
    game.weapons.equip(3)
    for i in range(20): await process_frame
    game.shoot()
    for i in range(54): await process_frame
    if game.viewmodel.animator.current_animation=="fire": failures.append("Mechanism still cycles after next shot becomes available")
    for i in range(40): await process_frame
    game.weapons.start_reload()
    if game.viewmodel.animator.get_playing_speed()>2.0: failures.append("Imported shell handling accelerated beyond double source speed")
    for i in range(100): await process_frame
    if game.weapons.ammo[3]!=6: failures.append("One complete shell cycle must add exactly one round")
    await preload("res://tests/cleanup.gd").finish(self,game)
    print("SHOTGUN_CYCLE_TEST ",JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
    quit(0 if failures.is_empty() else 1)
