extends SceneTree
var failures: Array = []
var game: Node
func _init() -> void: _run.call_deferred()
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func check(value: bool, message: String) -> void:
    if not value: failures.append(message)
func _run() -> void:
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    while game.phase == "loading":
        await physics_frame
        OS.delay_msec(1)
    await frames(5)
    print("NAV_DEBUG maps=",NavigationServer3D.get_maps()," regions=",NavigationServer3D.map_get_regions(game.get_world_3d().navigation_map)," iteration=",NavigationServer3D.map_get_iteration_id(game.get_world_3d().navigation_map))
    game.start_run()
    if game.get("enemies") == null:
        failures.append("Starting a run must spawn animated enemies")
    else:
        await frames(330)
        check(game.alive_count == 6,"Encounter must start with six living enemies")
        for enemy in game.enemies:
            var path := NavigationServer3D.map_get_path(game.get_world_3d().navigation_map, enemy.global_position, game.player.global_position, true)
            print("SPAWN_PATH ", enemy.global_position, " player=",game.player.global_position," closest=",NavigationServer3D.map_get_closest_point(game.get_world_3d().navigation_map,game.player.global_position)," path=",path)
            check(path.size() >= 2 and path[-1].distance_to(game.player.global_position) < 1.0, "Every spawn must reach the player")
        var enemy: Node3D = game.enemies[0]
        var initial: float = enemy.global_position.distance_to(game.player.global_position)
        await frames(120)
        print("PURSUIT ",enemy.global_position," vel=",enemy.velocity," next=",enemy.agent.get_next_path_position()," index=",enemy.agent.get_current_navigation_path_index()," initial=",initial)
        check(enemy.global_position.distance_to(game.player.global_position) < initial - 1,"Zombie must physically pursue, not only have a path")
        enemy.global_position = game.player.global_position+Vector3(0,0,-6)
        await frames(2)
        game.player.camera.look_at(enemy.global_position + Vector3.UP * 1.05)
        for shot in range(5):
            if enemy.dead: break
            game.player.camera.look_at(enemy.global_position + Vector3.UP * 1.05)
            game.weapons.tick(1)
            game.shoot()
            await frames(3)
        check(enemy.dead and game.alive_count == 5,"Actual hitscan shots must kill and count the zombie once")
        enemy.take_damage(999)
        check(game.alive_count == 5,"A corpse must not count twice")
        game.start_run()
        await frames(35)
        enemy = game.enemies[0]
        enemy.global_position = game.player.global_position + Vector3(0,0,-1.1)
        await frames(80)
        check(game.health < 100,"Animated melee must damage the player")
        game.start_run()
        await frames(35)
        enemy = game.enemies[0]
        enemy.global_position = game.player.global_position + Vector3(0,0,-1.1)
        await frames(10)
        check(enemy.attack_time >= 0,"Melee must have a windup")
        game.player.position.z += 3
        await frames(45)
        check(game.health == 100,"Moving out of the locked swipe must avoid damage")
        game.take_damage(100)
        check(game.phase == "dead" and not game.shoot(),"Defeat must stop shooting")
        game.start_run()
        await frames(5)
        check(game.health == 100 and game.alive_count+game.director.pending == 6,"Restart must restore the first wave")
        var guard := 0
        while game.phase=="running" and guard<3600:
            for living in game.enemies:
                if is_instance_valid(living) and not living.dead: living.take_damage(999)
            await frames(1)
            guard += 1
        check(game.phase == "won" and game.alive_count == 0 and game.director.kills==27,"All three waves must complete the survival run")
    await preload("res://tests/cleanup.gd").finish(self,game)
    print("ENCOUNTER_E2E ",JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
    var file := FileAccess.open("res://../encounter_test_report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"failures":failures},"  "))
    file.close()
    quit(0 if failures.is_empty() else 1)
