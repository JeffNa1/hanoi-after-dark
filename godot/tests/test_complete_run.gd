extends SceneTree
## Complete native three-wave playthrough using aim assistance, not lethal fixtures.
var game: Node
var failures: Array = []
var frames_ms: Array[float] = []
var held := false
var captures := 0
var captured_states: Array = []
func _init() -> void: run.call_deferred()
func trigger(down: bool) -> void:
    if down==held: return
    held = down
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = down
    Input.parse_input_event(event)
func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    var release: InputEventKey = event.duplicate()
    release.pressed = false
    Input.parse_input_event(release)
func run() -> void:
    root.unfocusable = true
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    await process_frame
    await process_frame
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../evidence/survival_run"))
    key(KEY_ENTER)
    await process_frame
    await process_frame
    if game.phase!="running":
        push_error("Native Enter did not start the complete-run test")
        quit(1)
        return
    game.director.random.seed = 612091
    key(KEY_2)
    var last_tick := Time.get_ticks_usec()
    var capture_wait := 0.0
    var wall_start := Time.get_ticks_msec()
    var max_active := 0
    var max_nodes := 0
    var capture_enabled := not OS.get_cmdline_user_args().has("--no-capture")
    while game.phase=="running" and Time.get_ticks_msec()-wall_start<240000:
        await process_frame
        var tick := Time.get_ticks_usec()
        frames_ms.append(float(tick-last_tick)/1000.0)
        last_tick = tick
        max_active = maxi(max_active,game.alive_count)
        max_nodes = maxi(max_nodes,get_node_count())
        var target: CharacterBody3D = null
        var nearest := 80.0
        for enemy in game.enemies:
            if not is_instance_valid(enemy) or enemy.dead: continue
            var distance: float = enemy.global_position.distance_to(game.player.global_position)
            if distance>=nearest: continue
            var query := PhysicsRayQueryParameters3D.create(game.player.camera.global_position,enemy.global_position+Vector3.UP,1|4)
            var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
            if not hit.is_empty() and hit.collider==enemy:
                target = enemy
                nearest = distance
        if target:
            var offset: Vector3 = target.global_position-game.player.global_position
            game.player.rotation.y = atan2(-offset.x,-offset.z)
            game.player.camera.look_at(target.global_position+Vector3.UP)
            if game.weapons.ammo[game.weapons.current]==0:
                trigger(false)
                if game.melee.remaining<=0:
                    if nearest<1.5: key(KEY_F)
                    else: key(KEY_R)
            else:
                trigger(true)
        else:
            trigger(false)
            if game.weapons.ammo[game.weapons.current]<15 and game.melee.remaining<=0: key(KEY_R)
        capture_wait -= root.get_process_delta_time()
        if capture_wait<=0 and capture_enabled:
            capture_wait = .2
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            image.resize(960,540,Image.INTERPOLATE_LANCZOS)
            image.save_jpg("res://../evidence/survival_run/%05d.jpg" % captures,.84)
            captured_states.append({"frame":captures,"time":game.director.elapsed,"wave":game.director.wave,"health":game.health,"kills":game.director.kills})
            captures += 1
    trigger(false)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../evidence/survival_complete.png")
    if game.phase!="won": failures.append("Real combat did not complete all three waves")
    if game.director.kills!=27: failures.append("Full run must resolve exactly 27 enemies")
    for record: Dictionary in game.director.spawn_records:
        if record.visible: failures.append("Enemy spawned in the current view")
    if max_active>8: failures.append("Active enemy cap exceeded")
    frames_ms.sort()
    var report := {"passed":failures.is_empty(),"failures":failures,"phase":game.phase,"kills":game.director.kills,"shots":game.shot_count,"health":game.health,"survivalSeconds":game.director.elapsed,"wallSeconds":float(Time.get_ticks_msec()-wall_start)/1000.0,"maxActiveEnemies":max_active,"maxNodes":max_nodes,"frames":frames_ms.size(),"frameMedianMs":frames_ms[frames_ms.size()/2],"frameP95Ms":frames_ms[int(frames_ms.size()*.95)],"frameP99Ms":frames_ms[int(frames_ms.size()*.99)],"maxFrameMs":frames_ms[-1],"spawnRecords":game.director.spawn_records,"captures":captured_states,"method":"Native GPU, real input trigger/reload and gameplay damage, navigation, spawns and ammunition. Automated aim assistance only; no health/ammo refill, enemy teleport, direct damage or invulnerability. Screenshots affect frame-time samples. Not a human difficulty evaluation."}
    report["captureEnabled"] = capture_enabled
    var report_name := "complete_playthrough.json" if capture_enabled else "complete_playthrough_performance.json"
    FileAccess.open("res://../reports/"+report_name,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("COMPLETE_PLAYTHROUGH ",JSON.stringify({"passed":report.passed,"failures":failures,"health":report.health,"kills":report.kills,"shots":report.shots,"seconds":report.survivalSeconds,"p95ms":report.frameP95Ms}))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
