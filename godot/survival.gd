extends Node
## Three finite waves. Spawns require an off-screen, connected navigation point.
const WAVE_COUNTS := [6,9,12]
const MAX_ACTIVE := 8
var game: Node
var wave := 1
var pending := 0
var kills := 0
var elapsed := 0.0
var intermission := 0.0
var spawn_wait := 0.0
var random := RandomNumberGenerator.new()
var roster: Array = []
var models: Dictionary = {}
var spawned := 0
var spawn_records: Array = []

func _ready() -> void:
    random.randomize()
    roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster.json"))

func reset() -> void:
    wave = 1
    pending = WAVE_COUNTS[0]
    kills = 0
    elapsed = 0
    intermission = 0
    spawn_wait = .35
    spawned = 0
    spawn_records.clear()

func preload_roster() -> void:
    # Retain resources during the run: modest memory cost avoids first-spawn disk stalls.
    for entry: Dictionary in roster:
        models[entry.key] = load("res://assets/"+entry.key+".glb")
        await get_tree().process_frame

func in_player_view(point: Vector3) -> bool:
    var camera: Camera3D = game.player.camera
    var viewport := camera.get_viewport().get_visible_rect().grow(90)
    for height in [.15,.95,1.85]:
        for side in [-.45,.45]:
            var sample: Vector3 = point + Vector3.UP*height + camera.global_basis.x*side
            if not camera.is_position_behind(sample) and viewport.has_point(camera.unproject_position(sample)):
                return true
    return false

func find_spawn() -> Variant:
    var origin: Vector3 = game.player.global_position
    var map: RID = game.get_world_3d().navigation_map
    for attempt in range(48):
        var angle := random.randf_range(-PI,PI)
        var radius := random.randf_range(12,28)
        var proposed := origin + Vector3(cos(angle)*radius,0,sin(angle)*radius)
        var point := NavigationServer3D.map_get_closest_point(map,proposed)
        if Vector2(point.x-origin.x,point.z-origin.z).length()<10 or absf(point.y-origin.y)>1:
            continue
        if in_player_view(point): continue
        var occupied := false
        for enemy in game.enemies:
            if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_squared_to(point)<3.24:
                occupied = true
                break
        if occupied: continue
        var route := NavigationServer3D.map_get_path(map,point,origin,true)
        if route.size()<2 or route[-1].distance_to(origin)>1: continue
        return point + Vector3.UP*.03
    # Never substitute a visible spawn when all safe candidates are occupied.
    return null

func tick(delta: float) -> void:
    if game.phase != "running": return
    elapsed += delta
    if intermission>0:
        intermission = maxf(0,intermission-delta)
        if intermission==0:
            wave += 1
            pending = WAVE_COUNTS[wave-1]
            spawn_wait = 0
        return
    if pending>0:
        spawn_wait = maxf(0,spawn_wait-delta)
        if spawn_wait>0 or game.alive_count>=MAX_ACTIVE: return
        var point: Variant = find_spawn()
        spawn_wait = .35 if point==null else .8
        if point==null: return
        var enemy := CharacterBody3D.new()
        enemy.set_script(game.Zombie)
        enemy.game = game
        enemy.model_key = roster[spawned % roster.size()].key
        enemy.position = point
        game.add_child(enemy)
        game.enemies.append(enemy)
        game.alive_count += 1
        game.fx.spawn_cue(point)
        pending -= 1
        spawned += 1
        spawn_records.append({"wave":wave,"model":enemy.model_key,"position":[point.x,point.y,point.z],"visible":in_player_view(point),"time":elapsed})
    elif game.alive_count==0:
        if wave==WAVE_COUNTS.size():
            game.finish_run()
        else:
            intermission = 7.0
            game.health = mini(100,game.health+20)
            for i in range(game.weapons.DEFINITIONS.size()):
                game.weapons.reserve[i] = mini(int(game.weapons.DEFINITIONS[i].reserve),game.weapons.reserve[i]+int(game.weapons.DEFINITIONS[i].capacity)*2)
