extends SceneTree
var game: Node
var failures: Array = []
func _init() -> void: _run.call_deferred()
func _run() -> void:
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    while game.phase == "loading":
        await physics_frame
        OS.delay_msec(1)
    game.start_run()
    game.player.position = Vector3(0,.05,-26)
    game.set_process(false)
    var walker := CharacterBody3D.new()
    walker.set_script(game.Zombie)
    walker.game = game
    walker.model_key = "vn_zombie_17_duong_sinh"
    game.add_child(walker)
    walker.position=NavigationServer3D.map_get_closest_point(game.get_world_3d().navigation_map,Vector3(-15,0,-10))+Vector3.UP*.03
    for i in range(5): await physics_frame
    var start := walker.global_position
    var goal: Vector3 = game.player.global_position
    var path := NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,start,goal,true)
    var length := 0.0
    for i in range(1,path.size()): length += path[i].distance_to(path[i-1])
    var direct := start.distance_to(goal)
    var block := PhysicsRayQueryParameters3D.create(start+Vector3.UP,goal+Vector3.UP,1)
    if game.get_world_3d().direct_space_state.intersect_ray(block).is_empty(): failures.append("Probe must have an actual building across the direct route")
    if length < direct * 1.15: failures.append("Navigation must route around the building")
    var steps := 0
    var traveled := 0.0
    var previous := walker.global_position
    while walker.global_position.distance_to(game.player.global_position) > 1.7 and steps < 2400:
        await physics_frame
        steps += 1
        traveled += walker.global_position.distance_to(previous)
        previous = walker.global_position
    if steps == 2400: failures.append("Zombie failed to physically follow its detour within 40 simulated seconds")
    var report := {"passed":failures.is_empty(),"failures":failures,"direct_m":direct,"route_m":length,"traveled_m":traveled,"physics_steps":steps,"remaining_m":walker.global_position.distance_to(game.player.global_position)}
    print("NAVIGATION_DETOUR_TEST ",JSON.stringify(report))
    var file := FileAccess.open("res://../navigation_detour_report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
