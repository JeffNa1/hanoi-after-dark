extends SceneTree
## Behavioral regression: off-screen reachable spawns and a complete three-wave run.
var game: Node
var failures: Array = []
var observations: Array = []
func _init() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
    if not ok: failures.append(message)
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func run() -> void:
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase == "loading": await physics_frame
    game.start_run()
    check(game.get("director") != null,"Survival director must own wave scheduling and off-screen spawning")
    if game.get("director") != null:
        var director: Node = game.director
        director.random.seed = 82341
        for location in [Vector3(1.15,.05,-3),Vector3(0,.05,-23),Vector3(0,.05,-42)]:
            game.player.position = location
            for yaw in [0.0,PI*.5,PI,PI*1.5]:
                game.player.rotation.y = yaw
                await frames(2)
                var found := false
                for retry in range(4):
                    var candidate: Variant = director.find_spawn()
                    if candidate == null: continue
                    found = true
                    check(not director.in_player_view(candidate),"Spawn must be wholly outside current view")
                    check(candidate.distance_to(location) >= 10,"Spawn must not appear next to player")
                    var route := NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,candidate,location,true)
                    check(route.size()>1 and route[-1].distance_to(location)<1,"Every spawn must reach the player")
                    break
                observations.append({"player":str(location),"yaw":yaw,"candidateFound":found})
                check(found,"Connected street must offer a hidden spawn at every tested heading")
        game.start_run()
        await frames(120)
        check(game.alive_count>0,"Queued enemies must actually spawn")
        var enemy: Node3D = game.enemies[0]
        var before: float = enemy.global_position.distance_to(game.player.global_position)
        await frames(120)
        check(enemy.global_position.distance_to(game.player.global_position)<before-.6,"Spawned enemy must physically pursue")
        game.pause_run()
        var clock: float = director.elapsed
        var queue: int = director.pending
        await frames(10)
        check(director.elapsed==clock and director.pending==queue,"Pause freezes survival clock and spawns")
        game.resume_run()
        game.take_damage(100)
        check(game.phase=="dead" and not game.shoot(),"Death stops shooting")
        var count: int = game.alive_count
        await frames(40)
        check(game.alive_count==count,"Death stops the spawn queue")
        game.start_run()
        check(game.health==100 and director.wave==1 and director.kills==0,"Restart resets health, wave and kills")
        var guard := 0
        while game.phase=="running" and guard<3000:
            for living in game.enemies:
                if is_instance_valid(living) and not living.dead: living.take_damage(999)
            await frames(1)
            guard += 1
        check(game.phase=="won" and director.wave==3,"Three cleared waves must produce victory")
        check(director.kills==27 and game.alive_count==0 and director.pending==0,"Exactly 27 threats must be resolved once")
        check(not game.shoot(),"Victory stops shooting")
        game.start_run()
        check(director.wave==1 and director.kills==0 and game.shot_count==0,"Victory restart resets the whole run")
        director.wave = 3
        director.pending = 12
        await frames(440)
        check(game.alive_count==8 and director.pending==4,"A controlled third-wave fixture must defer enemies above the eight-active cap")
        game.take_damage(100)
    var report := {"passed":failures.is_empty(),"failures":failures,"spawnProbes":observations,"method":"Real Godot navigation and enemy pursuit; lethal fixture accelerates wave completion, not a balance playtest."}
    FileAccess.open("res://../reports/survival_logic.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("SURVIVAL_LOGIC ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
