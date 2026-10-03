extends SceneTree
var game: Node
var failures: Array = []
var evidence: Array = []
func _init() -> void: _run.call_deferred()
func frames(count: int) -> void:
    for i in range(count): await process_frame
func key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
func mouse(button: MouseButton, down: bool) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = button
    event.pressed = down
    Input.parse_input_event(event)
func tap(code: Key) -> void:
    key(code,true)
    await frames(2)
    key(code,false)
func check(ok: bool, description: String) -> void:
    if not ok: failures.append(description)
func capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/"+label+".png"))
    evidence.append({"frame":label,"phase":game.phase,"health":game.health,"alive":game.alive_count})
func _run() -> void:
    root.unfocusable = true
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    while game.phase == "loading": await process_frame
    await frames(5)
    await capture("fps_ready")
    await tap(KEY_ENTER)
    check(game.phase == "running","Native Enter must start")
    check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,"Native mouse must capture")
    await frames(310)
    for enemy in game.enemies: enemy.set_physics_process(false)
    var start: Vector3 = game.player.position
    key(KEY_W,true)
    await frames(40)
    key(KEY_W,false)
    await frames(2)
    var walk: float = game.player.position.distance_to(start)
    check(walk > 1.8,"Native W must walk")
    start = game.player.position
    key(KEY_SHIFT,true)
    key(KEY_W,true)
    await frames(40)
    key(KEY_W,false)
    key(KEY_SHIFT,false)
    await frames(2)
    var sprint: float = game.player.position.distance_to(start)
    check(sprint > walk*1.4,"Native Shift must increase speed")
    await tap(KEY_SPACE)
    await frames(8)
    check(game.player.position.y > .2,"Native Space must jump")
    await frames(40)
    var old_yaw: float = game.player.rotation.y
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(25,-10)
    Input.parse_input_event(motion)
    await frames(2)
    check(absf(game.player.rotation.y-old_yaw) > .02,"Native mouse motion must rotate view")
    mouse(MOUSE_BUTTON_RIGHT,true)
    await frames(24)
    check(game.player.aiming and game.player.camera.fov < 56,"Native RMB must aim")
    await capture("fps_aim")
    mouse(MOUSE_BUTTON_RIGHT,false)
    for index in range(4):
        await tap(KEY_1+index)
        await frames(18)
        check(game.weapons.current == index,"Native weapon selection " + str(index))
        var shots: int = game.shot_count
        mouse(MOUSE_BUTTON_LEFT,true)
        await frames(24)
        mouse(MOUSE_BUTTON_LEFT,false)
        check(game.shot_count > shots,"Native LMB must fire " + str(index))
        if index in [1,2]: check(game.shot_count >= shots+3,"Automatic held fire " + str(index))
        if index in [0,3]: check(game.shot_count == shots+1,"Semi automatic must require next press")
        await tap(KEY_R)
        check(game.weapons.reload_remaining > 0,"Native R must reload " + str(index))
        await frames(int(game.weapons.spec().reload * 60)+5)
        check(game.weapons.ammo[index] == game.weapons.spec().capacity,"Native reload must refill " + str(index))
    game.start_run()
    await frames(80)
    var enemy: CharacterBody3D = game.enemies[0]
    enemy.set_physics_process(false)
    enemy.position = Vector3(1.15,.0,-8)
    var wall := StaticBody3D.new()
    wall.collision_layer = 1
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(3,3,.25)
    shape.shape = box
    wall.add_child(shape)
    game.add_child(wall)
    wall.position = Vector3(1.15,1.5,-5)
    await frames(3)
    var health: float = enemy.health
    game.player.camera.look_at(enemy.global_position+Vector3.UP)
    mouse(MOUSE_BUTTON_LEFT,true)
    await frames(3)
    mouse(MOUSE_BUTTON_LEFT,false)
    check(enemy.health == health,"World walls must block hitscan")
    wall.queue_free()
    await frames(20)
    game.player.camera.look_at(enemy.global_position+Vector3.UP)
    var before_shot: int = game.shot_count
    mouse(MOUSE_BUTTON_LEFT,true)
    await frames(6)
    mouse(MOUSE_BUTTON_LEFT,false)
    print("NATIVE_TARGET_SHOT ",JSON.stringify({"before":before_shot,"after":game.shot_count,"health_before":health,"health_after":enemy.health,"mouse_mode":Input.mouse_mode,"cooldown":game.weapons.cooldown}))
    check(game.shot_count == before_shot+1,"Unobstructed input must produce one shot")
    check(enemy.health < health,"Unobstructed native shot must damage actual zombie")
    await capture("fps_combat")
    enemy.set_physics_process(true)
    enemy.position = game.player.position+Vector3(0,0,-1.1)
    await frames(30)
    check(enemy.attack_time >= 0,"Melee probe must wait for hit flinch before the windup")
    await capture("fps_melee_windup")
    await frames(40)
    check(game.health < 100,"Real enemy melee must remove health")
    await tap(KEY_ESCAPE)
    check(game.phase == "paused" and paused,"Escape must pause")
    var stopped: Vector3 = enemy.position
    await frames(30)
    check(enemy.position.is_equal_approx(stopped),"Pause must stop enemy movement")
    await capture("fps_paused")
    await tap(KEY_ESCAPE)
    check(game.phase == "running" and not paused,"Escape must resume")
    game.take_damage(200)
    await frames(3)
    await capture("fps_defeat")
    await tap(KEY_ENTER)
    check(game.phase == "running" and game.health == 100 and game.alive_count+game.director.pending == 6,"Native restart must restore run")
    var wave_guard := 0
    while game.phase=="running" and wave_guard<3600:
        for living in game.enemies:
            if is_instance_valid(living) and not living.dead: living.take_damage(999)
        await frames(1)
        wave_guard += 1
    await capture("fps_victory")
    check(game.phase == "won","Controlled final kill must show success")
    var report := {"passed":failures.is_empty(),"failures":failures,"walk_m":walk,"sprint_m":sprint,"evidence":evidence,"method":"GPU runtime with injected native InputEvents; movement enemies frozen, wall and lethal outcomes controlled fixtures; not a human balance playtest"}
    var file := FileAccess.open("res://../native_gameplay_report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("NATIVE_GAMEPLAY_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
