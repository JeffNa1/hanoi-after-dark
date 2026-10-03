extends SceneTree
var failures: Array = []

func _init() -> void:
    _run.call_deferred()

func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func _run() -> void:
    if not ResourceLoader.exists("res://FPS.tscn"):
        check(false, "The playable first-person scene must exist")
        finish()
        return
    var game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    while game.phase == "loading":
        await physics_frame
        OS.delay_msec(1)
    for frame in range(5):
        await physics_frame
    game.start_run()
    check(game.phase == "running" and game.health == 100, "Start enters a live run")
    check(game.viewmodel.animator != null, "Actual hands have an animation player")
    check(game.viewmodel.animator.has_animation("reload"), "Actual reload animation is present")
    check(game.shoot(), "A live loaded player can shoot")
    check(game.weapons.ammo[0] == 11, "Shot consumes ammunition")
    check(not game.shoot(), "Same-frame double shot is blocked")
    game.take_damage(200)
    check(game.phase == "dead" and game.health == 0, "Lethal damage enters defeat")
    check(not game.shoot(), "Dead player cannot shoot")
    game.start_run()
    check(game.health == 100 and game.weapons.ammo[0] == 12, "Restart resets health and ammunition")
    for frame in range(20):
        await process_frame
    await preload("res://tests/cleanup.gd").finish(self,game)
    finish()

func finish() -> void:
    print("FPS_SLICE_TEST ", JSON.stringify({"passed": failures.is_empty(), "failures": failures}))
    quit(0 if failures.is_empty() else 1)
