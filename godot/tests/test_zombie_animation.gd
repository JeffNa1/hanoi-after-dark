extends SceneTree
## Native silhouettes and bone poses during real zombie AI, not manually played clips.
var game: Node
var enemy: CharacterBody3D
var view: SubViewport
var camera: Camera3D
var failures: Array = []
var rows: Array = []
var capture := false

func _init() -> void: run.call_deferred()
func check(ok: bool, why: String) -> void:
    if not ok: failures.append(why)
func frames(count: int) -> void:
    for i in range(count): await process_frame
func key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
func pose() -> Array:
    var skeleton: Skeleton3D = enemy.find_children("*","Skeleton3D",true,false)[0]
    var result: Array = []
    for bone in ["pelvis","spine_03","head","hand_l","hand_r","foot_l","foot_r"]:
        result.append(skeleton.get_bone_global_pose(skeleton.find_bone(bone)))
    return result
func silhouette_difference(a: PackedByteArray, b: PackedByteArray) -> int:
    var changed := 0
    for i in range(3,a.size(),4):
        if (a[i]>100) != (b[i]>100): changed += 1
    return changed
func sample(clip: String, count: int) -> Dictionary:
    var first := PackedByteArray()
    var first_pose: Array = []
    var changed := 0
    var pose_changes := 0
    var peak_image: Image
    var peak_frame := 0
    var clock_progress := 0.0
    var observed := {}
    var samples := 0
    for i in range(count):
        await process_frame
        # Cancel actor translation and yaw. Pixels can change only with the visible pose.
        camera.global_transform = enemy.global_transform
        camera.translate_object_local(Vector3(2,1.25,3))
        camera.look_at(enemy.global_position+Vector3.UP*.85)
        await RenderingServer.frame_post_draw
        observed[str(enemy.animator.assigned_animation)] = true
        if enemy.animator.assigned_animation == clip:
            clock_progress = maxf(clock_progress,enemy.animator.current_animation_position/enemy.animator.get_animation(clip).length)
        if i % 3 != 0 and i != count-1: continue
        var image := view.get_texture().get_image()
        image.convert(Image.FORMAT_RGBA8)
        var pixels := image.get_data()
        var current_pose := pose()
        if first.is_empty():
            first = pixels
            first_pose = current_pose
        else:
            var difference := silhouette_difference(first,pixels)
            if difference>changed:
                changed = difference
                peak_image = image
                peak_frame = i
            for bone in range(current_pose.size()):
                if not current_pose[bone].is_equal_approx(first_pose[bone]):
                    pose_changes += 1
                    break
        if capture and i in [0,count-1]:
            image.save_png("res://../evidence/zombie_animation/%s_%s_%03d.png" % [enemy.model_key,clip,i])
        samples += 1
    var visible := 0
    for i in range(3,first.size(),4):
        if first[i]>100: visible += 1
    var prefix: String = enemy.model_key+"/"+clip
    check(observed.has(clip),prefix+" must be selected by gameplay")
    check(clock_progress>.1,prefix+" animation clock must advance")
    check(visible>500,prefix+" must render a visible body")
    check(pose_changes>=3,prefix+" must change bone poses, not only its clock")
    check(changed>=30,prefix+" must change the GPU silhouette, not only CPU bones")
    if capture and peak_image:
        peak_image.save_png("res://../evidence/zombie_animation/%s_%s_peak.png" % [enemy.model_key,clip])
    var row := {"model":enemy.model_key,"clip":clip,"observed":observed.keys(),"samples":samples,"poseChanges":pose_changes,"changedSilhouettePixels":changed,"visiblePixels":visible,"maxNormalizedTime":clock_progress,"peakFrame":peak_frame}
    rows.append(row)
    return row

func run() -> void:
    if DisplayServer.get_name()=="headless":
        push_error("Run this regression with the native renderer, not --headless")
        quit(1)
        return
    root.unfocusable = true
    capture = OS.get_cmdline_user_args().has("--capture")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports"))
    if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../evidence/zombie_animation"))
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    view = SubViewport.new()
    view.size = Vector2i(320,320)
    view.transparent_bg = true
    view.world_3d = game.get_world_3d()
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    camera = Camera3D.new()
    camera.cull_mask = 2
    camera.fov = 40
    view.add_child(camera)
    for index in range(game.director.roster.size()):
        game.start_run()
        game.set_process(true)
        game.player.set_physics_process(false)
        game.director.random.seed = 81261+index
        game.director.spawned = index
        game.director.pending = 1
        game.director.spawn_wait = 0
        var guard := 0
        while game.enemies.is_empty() and guard<180:
            await frames(1)
            guard += 1
        check(not game.enemies.is_empty(),"Real director must spawn roster entry "+str(index))
        if game.enemies.is_empty(): break
        game.set_process(false) # Isolate one actor; its physics and animation keep running.
        enemy = game.enemies[0]
        check(enemy.model_key==game.director.roster[index].key,"Spawned roster order")
        for mesh: MeshInstance3D in enemy.find_children("*","MeshInstance3D",true,false):
            mesh.layers = 2
            if mesh.skin: check(mesh.get_skin_reference()!=null,enemy.model_key+" must register its render skin")
        enemy.position = Vector3(1.15,0,-12)
        enemy.repath = 0
        var wall := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = Vector3(4,3,.4)
        collision.shape = box
        wall.add_child(collision)
        wall.position = Vector3(1.15,1.5,-11.5)
        game.add_child(wall)
        await frames(45)
        await sample("idle",36) # A blocked actor idles while the game is still running.
        wall.queue_free()
        await frames(12)
        var start: Vector3 = enemy.position
        await sample("walk",48)
        check(enemy.position.distance_to(start)>.8,enemy.model_key+" walk must translate the body")
        game.pause_run()
        var paused_pose := pose()
        var paused_time: float = enemy.animator.current_animation_position
        await frames(8)
        check(pose()==paused_pose and enemy.animator.current_animation_position==paused_time,"Pause freezes pose and animation clock")
        game.resume_run()
        enemy.position = Vector3(1.15,0,-24)
        enemy.repath = 0
        game.player.set_physics_process(true)
        key(KEY_W,true)
        key(KEY_SHIFT,true)
        await frames(12)
        await sample("run",36)
        key(KEY_W,false)
        key(KEY_SHIFT,false)
        await frames(12)
        game.player.set_physics_process(false)
        check(enemy.animator.assigned_animation=="walk",enemy.model_key+" returns to walk when sprint pursuit ends")
        enemy.position = game.player.position+Vector3(0,0,-1.1)
        guard = 0
        while enemy.attack_time<0 and guard<30:
            await frames(1)
            guard += 1
        var health_before: int = game.health
        await sample("attack",38)
        check(game.health==health_before-18,enemy.model_key+" attack applies one contact hit")
        enemy.take_damage(1)
        check(enemy.attack_time<0,enemy.model_key+" flinch cancels attack")
        var hit := await sample("hit",15)
        check(hit.maxNormalizedTime>=.80,enemy.model_key+" full hit reaction must fit the flinch window")
        enemy.take_damage(1)
        check(enemy.animator.current_animation_position<.05,enemy.model_key+" repeated hits restart the reaction")
        await frames(22)
        enemy.take_damage(999)
        var kills: int = game.director.kills
        enemy.take_damage(999)
        check(enemy.dead and game.director.kills==kills and kills==1,"Death counts once")
        check(enemy.collision_layer==0 and enemy.collision_mask==0,"Corpse stops blocking movement and shots")
        game.finish_run()
        await sample("death",190)
        var final_pose := pose()
        await frames(12)
        check(pose()==final_pose,"Death holds its final pose instead of returning to idle")
        await frames(225)
        check(not is_instance_valid(enemy),"Corpse is removed after its lifetime")
    key(KEY_W,false)
    key(KEY_SHIFT,false)
    game.start_run()
    check(game.health==100 and game.enemies.is_empty() and game.director.kills==0,"Restart clears the old animation actors and combat state")
    check(rows.size()==78,"All six gameplay animation states must be sampled for all 13 models")
    var report := {"passed":failures.is_empty(),"failures":failures,"states":rows,"method":"Native real director/AI/input/damage transitions. Isolated alpha silhouettes follow each actor to remove world translation/yaw. No test calls AnimationPlayer.play, seek or advance."}
    FileAccess.open("res://../reports/zombie_animation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("ZOMBIE_ANIMATION_TEST ",JSON.stringify({"passed":report.passed,"states":rows.size(),"failures":failures}))
    view.queue_free()
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
