extends SceneTree
const SoleProbe = preload("res://tests/sole_probe.gd")
var failures: Array = []
func _init() -> void: _run.call_deferred()
func _run() -> void:
    var game: Node = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    game.start_run()
    game.player.set_physics_process(false)
    var arguments := OS.get_cmdline_user_args()
    var index: int=int(arguments[0]) if not arguments.is_empty() else 4
    game.set_process(false)
    var models := ["zombie","vn_zombie_12_xiec_lua","vn_zombie_15_tiktoker","vn_zombie_16_sua_xe","vn_zombie_17_duong_sinh"]
    var enemy := CharacterBody3D.new()
    enemy.set_script(game.Zombie)
    enemy.game = game
    enemy.model_key = models[index]
    game.add_child(enemy)
    enemy.position=NavigationServer3D.map_get_closest_point(game.get_world_3d().navigation_map,Vector3(-15,0,-10))+Vector3.UP*.03
    game.player.position=Vector3(0,.05,-26)
    enemy.rotation.y=PI/2
    var probe := SoleProbe.new(enemy)
    var final_ik := {}
    var planting: Node=probe.skeleton.find_children("*","SkeletonModifier3D",false,false)[0]
    probe.skeleton.skeleton_updated.connect(func():
        for foot in planting.feet:
            var ankle: Vector3=probe.skeleton.global_transform*probe.skeleton.get_bone_global_pose(foot.bone).origin
            final_ik[foot.bone]={"goal_error":ankle.distance_to(foot.target.global_position),"goal":str(foot.target.global_position),"ankle":str(ankle),"locked":foot.locked}
    )
    var contacts := {"l":{},"r":{}}
    var maximum_drift := 0.0
    var total_turn := 0.0
    var last_yaw := enemy.rotation.y
    var stance_count := 0
    var worst := {}
    for frame in range(1500):
        await process_frame
        total_turn += absf(wrapf(enemy.rotation.y-last_yaw,-PI,PI))
        last_yaw=enemy.rotation.y
        if enemy.animator.current_animation!="walk": continue
        var feet: Dictionary=probe.measure()
        var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,enemy.position-Vector3.UP,1))
        if hit.is_empty():
            failures.append("Missing physical floor")
            break
        for side in ["l","r"]:
            var foot: Dictionary=feet[side]
            if foot.high-hit.position.y<.035 and foot.low-hit.position.y>=-.03:
                if contacts[side].is_empty(): contacts[side]={"point":foot.centroid,"frames":0,"drift":0.0}
                var difference: Vector3=foot.centroid-contacts[side].point
                difference.y=0
                contacts[side].frames+=1
                contacts[side].drift=maxf(contacts[side].drift,difference.length())
                if contacts[side].drift>float(worst.get("drift",0)):
                    var skeleton: Skeleton3D=enemy.find_children("*","Skeleton3D",true,false)[0]

                    var foot_index: int=0 if side=="l" else 1
                    var tracked: Dictionary=planting.feet[foot_index]
                    var ankle: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(tracked.bone).origin
                    worst={"drift":contacts[side].drift,"frame":frame,"side":side,"clip_time":enemy.animator.current_animation_position,"body":str(enemy.position),"final_ik":final_ik[tracked.bone],"goal_error":ankle.distance_to(tracked.target.global_position),"locked":tracked.locked,"phase":game.phase}
            else:
                if not contacts[side].is_empty() and contacts[side].frames>=6:
                    maximum_drift=maxf(maximum_drift,contacts[side].drift)
                    stance_count+=1
                contacts[side]={}
    if total_turn<.6: failures.append("Fixture did not traverse a real corner")
    if stance_count<8: failures.append("Too few support phases")
    if maximum_drift>.045: failures.append("Planted sole slips more than 4.5cm while cornering")
    game.phase="ready"
    for i in range(45): await process_frame
    var stopped: Dictionary=probe.measure()
    var stop_drift:=0.0
    for i in range(45):
        await process_frame
        var feet: Dictionary=probe.measure()
        for side in ["l","r"]: stop_drift=maxf(stop_drift,feet[side].centroid.distance_to(stopped[side].centroid))
    if stop_drift>.005: failures.append("Settled stopped soles move more than 5mm")
    if enemy.animator.speed_scale!=1.0: failures.append("Walk speed leaks into idle")
    var report:={"passed":failures.is_empty(),"failures":failures,"turn_radians":total_turn,"stances":stance_count,"max_stance_drift_m":maximum_drift,"settled_stop_drift_m":stop_drift,"scope":"Actual corner pursuit plus a controlled ready-state stop; occupied CPU-skinned soles, not human visual approval."}
    FileAccess.open("res://../reports/gait_corners.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    report["model"]=enemy.model_key
    FileAccess.open("res://../reports/gait_corners_"+enemy.model_key+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("GAIT_CORNER_WORST ",JSON.stringify(worst))
    print("GAIT_CORNERS_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
