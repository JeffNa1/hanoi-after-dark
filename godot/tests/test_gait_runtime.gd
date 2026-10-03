extends SceneTree
const SoleProbe = preload("res://tests/sole_probe.gd")
var failures: Array = []
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
    if not ok: failures.append(message)
func _run() -> void:
    var game: Node3D = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase == "loading": await process_frame
    game.start_run()
    game.player.set_physics_process(false)
    game.set_process(false)
    var enemy := CharacterBody3D.new()
    enemy.set_script(game.Zombie)
    enemy.game = game
    enemy.model_key = "zombie"
    game.add_child(enemy)
    enemy.position = Vector3(1.15,0,-38)
    enemy.rotation.y = 0
    var probe := SoleProbe.new(enemy)
    check(probe.samples.l.size() >= 3 and probe.samples.r.size() >= 3,"Both visible soles need occupied mesh samples")
    for i in range(90): await process_frame
    var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,enemy.position-Vector3.UP,1))
    check(not floor_hit.is_empty(),"Gait test must stand over the actual collision floor")
    var floor_y: float = floor_hit.position.y
    var start: Vector3 = enemy.position
    var contacts := {"l":{},"r":{}}
    var stance_runs: Array = []
    var frames: Array = []
    var highest_support := 0.0
    var penetration := 0.0
    var lift := {"l":0.0,"r":0.0}
    for frame in range(360):
        await process_frame
        var soles: Dictionary = probe.measure()
        highest_support = maxf(highest_support,minf(soles.l.low,soles.r.low)-floor_y)
        penetration = minf(penetration,minf(soles.l.low,soles.r.low)-floor_y)
        var row := {"frame":frame,"body":str(enemy.position),"clip":str(enemy.animator.current_animation),"time":enemy.animator.current_animation_position,"feet":{}}
        for side in ["l","r"]:
            var foot: Dictionary = soles[side]
            lift[side] = maxf(lift[side],foot.low-floor_y)
            var point: Vector3 = foot.centroid
            row.feet[side] = {"x":point.x,"y":point.y,"z":point.z,"low":foot.low-floor_y}
            if foot.high-floor_y < .035 and foot.low-floor_y >= -.03:
                if contacts[side].is_empty():
                    contacts[side] = {"start":point,"frames":0,"drift":0.0,"side":side}
                contacts[side].frames += 1
                var displacement: Vector3 = point - contacts[side].start
                displacement.y = 0
                contacts[side].drift = maxf(contacts[side].drift,displacement.length())
            else:
                if not contacts[side].is_empty() and contacts[side].frames >= 6:
                    stance_runs.append(contacts[side].duplicate())
                contacts[side] = {}
        frames.append(row)
    for side in ["l","r"]:
        if not contacts[side].is_empty() and contacts[side].frames >= 6: stance_runs.append(contacts[side].duplicate())
    var max_drift := 0.0
    for stance in stance_runs: max_drift = maxf(max_drift,stance.drift)
    check(enemy.position.distance_to(start) > 6.0,"The tested actor must actually traverse the map")
    check(stance_runs.size() >= 8,"Moving feet must alternate visible flat support for at least eight stances")
    check(max_drift < .045,"A planted visible sole must drift less than 4.5cm in a straight stance")
    check(highest_support < .03,"Walking must keep a visible sole within 3cm of the real floor")
    check(penetration > -.025,"Visible feet must not penetrate the real floor by more than 2.5cm")
    check(lift.l > .06 and lift.r > .06,"Both feet must lift at least 6cm during real movement")
    var report := {"passed":failures.is_empty(),"failures":failures,"sole_vertices":{"l":probe.samples.l.size(),"r":probe.samples.r.size()},"travel_m":enemy.position.distance_to(start),"stance_count":stance_runs.size(),"max_stance_drift_m":max_drift,"highest_support_m":highest_support,"penetration_m":penetration,"lift_m":lift,"stance_runs":stance_runs,"frames":frames,"scope":"Actual Godot pursuit; independent CPU-skinned occupied sole vertices; straight path only"}
    FileAccess.open("res://../reports/gait_runtime.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    report.erase("frames")
    report.erase("stance_runs")
    print("GAIT_RUNTIME_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
