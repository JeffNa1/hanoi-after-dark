extends SceneTree
func _init() -> void: _run.call_deferred()
func _run() -> void:
    var game: Node = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase == "loading": await process_frame
    game.start_run()
    for enemy in game.enemies: enemy.set_physics_process(false)
    game.shoot()
    game.weapons.start_reload()
    for i in range(int(game.weapons.spec().reload*60)+6): await process_frame
    var report := {"passed":game.weapons.reload_remaining==0 and game.viewmodel.animator.current_animation=="idle","gameplay_remaining":game.weapons.reload_remaining,"visible_animation":game.viewmodel.animator.current_animation,"method":"Actual clock update through the game scene; the magazine cannot refill while the visible reload continues"}
    print("RELOAD_SYNC_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if report.passed else 1)
