extends SceneTree
## Actual AnimationPlayer playback of every integrated roster asset.
const Actor = preload("res://zombie.gd")
class ReviewContext extends Node:
    var phase := "review"
var failures: Array = []
var rows: Array = []
var stage: Node3D
var context: Node
var camera: Camera3D
func _init() -> void: run.call_deferred()
func run() -> void:
    root.unfocusable = true
    root.size = Vector2i(768, 512)
    stage = Node3D.new()
    root.add_child(stage)
    context = ReviewContext.new()
    stage.add_child(context)
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color(.075,.09,.10)
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color(.8,.86,.88)
    world.environment.ambient_light_energy = .7
    stage.add_child(world)
    var lamp := DirectionalLight3D.new()
    lamp.rotation_degrees = Vector3(-45,-25,0)
    lamp.light_energy = 1.4
    lamp.shadow_enabled = true
    stage.add_child(lamp)
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(12,12)
    floor_mesh.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(.18,.20,.21)
    floor_mesh.material_override = material
    stage.add_child(floor_mesh)
    camera = Camera3D.new()
    stage.add_child(camera)
    camera.position = Vector3(1.8,1.55,3.1)
    camera.look_at(Vector3(0,.85,0))
    camera.fov = 45
    var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster.json"))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../evidence/attacks_runtime"))
    for entry: Dictionary in roster:
        var actor := Actor.new()
        actor.game = context
        actor.model_key = entry.key
        stage.add_child(actor)
        actor.set_physics_process(false)
        var skeleton: Skeleton3D = actor.find_children("*", "Skeleton3D", true, false)[0]
        var model_rows: Array = []
        for clip: String in ["idle","walk","run","attack","hit","death"]:
            if not actor.animator.has_animation(clip):
                failures.append(entry.key + " missing " + clip)
                continue
            var speed := 2.2 if clip == "attack" else 2.0
            actor.animator.play(clip, .06, speed)
            var duration := actor.animator.get_animation(clip).length / speed
            var elapsed := 0.0
            var poses := {}
            var frame := 0
            var captured := false
            while elapsed < duration + .03:
                await process_frame
                var delta := root.get_process_delta_time()
                elapsed += delta
                var hand := skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
                if not hand.is_finite(): failures.append(entry.key+" non-finite "+clip)
                poses[str(hand.origin.snapped(Vector3(.0001,.0001,.0001)))] = true
                if clip == "attack":
                    await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png("res://../evidence/attacks_runtime/%s_%03d.png" % [entry.key,frame])
                    frame += 1
                    if elapsed >= .55 and not captured:
                        root.get_texture().get_image().save_png("res://../evidence/attacks_runtime/%s_contact.png" % entry.key)
                        captured = true
            model_rows.append({"clip":clip,"duration":duration,"poseCount":poses.size(),"frames":frame})
            if clip == "attack" and poses.size() < 5: failures.append(entry.key+" static attack")
        rows.append({"id":entry.id,"clips":model_rows})
        actor.queue_free()
        await process_frame
    if rows.size() != 13: failures.append("Wrong retained roster count")
    var report := {"passed":failures.is_empty(),"failures":failures,"models":rows,"scope":"Native per-frame AnimationPlayer playback of all 13 integrated GLBs, six clips each; attack frames captured at fixed 30fps. Not human approval or full survival testing."}
    FileAccess.open("res://../reports/attack_milestone_runtime.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("ATTACK_MILESTONE_RUNTIME ",JSON.stringify(report))
    stage.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
