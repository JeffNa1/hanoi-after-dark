extends SceneTree
var game: Node
var failures: Array = []
func _init() -> void: run.call_deferred()
func check(ok: bool, why: String) -> void:
    if not ok: failures.append(why)
func run() -> void:
    root.unfocusable = true
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    var recorder := AudioEffectRecord.new()
    recorder.format = AudioStreamWAV.FORMAT_16_BITS
    AudioServer.add_bus_effect(0,recorder)
    recorder.set_recording_active(true)
    game.start_run()
    await create_timer(1.5).timeout
    check(game.fx.events.spawn>0,"Off-screen spawns produce positional warnings")
    check(game.fx.music.playing,"Licensed music must actually play")
    check(game.fx.music.stream.loop,"Ambient music must loop")
    var enemy: CharacterBody3D = game.enemies[0]
    enemy.set_physics_process(false)
    enemy.position = game.player.position+Vector3(0,0,-3)
    await physics_frame
    game.player.camera.look_at(enemy.global_position+Vector3.UP)
    for i in range(4):
        game.shoot()
        await create_timer(.32).timeout
    check(game.fx.events.shot>0 and game.fx.events.pain>0 and game.fx.events.death==1,"Gunfire, injury and death must produce actual feedback events")
    var key := InputEventKey.new()
    key.keycode = KEY_W
    key.physical_keycode = KEY_W
    key.pressed = true
    Input.parse_input_event(key)
    await create_timer(1.1).timeout
    key.pressed = false
    Input.parse_input_event(key)
    game.melee.start()
    await create_timer(.8).timeout
    check(game.fx.events.step>0 and game.fx.events.swing==1,"Walking and crowbar produce recorded foley")
    check(game.fx.voices.size()==8 and game.fx.particles.size()==8,"Audio and particles stay in fixed pools")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../evidence/feedback_runtime.png")
    game.take_damage(100)
    await create_timer(1.0).timeout
    recorder.set_recording_active(false)
    var recording := recorder.get_recording()
    var path := ProjectSettings.globalize_path("res://../evidence/survival_master_bus.wav")
    recording.save_to_wav(path)
    var report := {"passed":failures.is_empty(),"failures":failures,"events":game.fx.events.duplicate(),"recording":path,"audioBytes":recording.data.size(),"method":"Actual GPU runtime and native master-bus recording, real timers. Not human listening approval."}
    FileAccess.open("res://../reports/feedback_runtime.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("FEEDBACK_RUNTIME ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
