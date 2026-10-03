extends SceneTree
const SoleProbe = preload("res://tests/sole_probe.gd")
var expected: Array = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game: Node3D=load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    game.start_run()
    game.player.set_physics_process(false)
    game.set_process(false)
    for entry in game.director.roster: expected.append(entry.key)
    var rows: Array = []
    var failures: Array = []
    for index in range(expected.size()):
        var enemy := CharacterBody3D.new()
        enemy.set_script(game.Zombie)
        enemy.game=game
        enemy.model_key=expected[index]
        game.add_child(enemy)
        enemy.position=Vector3(1.15,0,-38)
        enemy.rotation.y=0
        enemy.velocity=Vector3.ZERO
        enemy.repath=0
        enemy.collision_layer=4
        enemy.collision_mask=1|2|4
        enemy.set_physics_process(true)
        for frame in range(90): await physics_frame
        var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,enemy.position-Vector3.UP,1))
        var floor_y: float=hit.position.y
        var probe = SoleProbe.new(enemy)
        var anchors := {}
        var contacts := 0
        var drift := 0.0
        var penetration := 0.0
        var start := enemy.global_position
        for frame in range(240):
            await physics_frame
            var feet: Dictionary=probe.measure()
            for side in ["l","r"]:
                var foot: Dictionary=feet[side]
                penetration=minf(penetration,foot.low-floor_y)
                if foot.high-floor_y<.035 and foot.low-floor_y>=-.03:
                    if not anchors.has(side):
                        anchors[side]=foot.centroid
                        contacts+=1
                    var movement: Vector3=foot.centroid-anchors[side]
                    drift=maxf(drift,Vector2(movement.x,movement.z).length())
                else: anchors.erase(side)
        enemy.set_physics_process(false)
        enemy.collision_layer=0
        enemy.collision_mask=0
        var distance := enemy.global_position.distance_to(start)
        var valid := contacts>=6 and drift<=.045 and penetration>=-.025 and distance>4.5
        rows.append({"model":expected[index],"contacts":contacts,"maxDriftMeters":drift,"penetrationMeters":penetration,"distanceMeters":distance,"passed":valid})
        if not valid: failures.append(expected[index])
        enemy.queue_free()
    var result := {"passed":failures.is_empty(),"models":rows,"failures":failures,"scope":"Actual pursuit and independent occupied-sole measurements for every playable model; not human animation approval."}
    FileAccess.open("res://../reports/roster_runtime.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print("ROSTER_RUNTIME_TEST ",JSON.stringify(result))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
