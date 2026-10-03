extends Node3D
const WeaponState = preload("res://weapon_state.gd")
const Player = preload("res://fps_player.gd")
const Viewmodel = preload("res://viewmodel.gd")
const HUD = preload("res://hud.gd")
const ShotAudio = preload("res://shot_audio.gd")
const Zombie = preload("res://zombie.gd")
const Survival = preload("res://survival.gd")
var director: Node
var melee: Node
var fx: Node3D
var atmosphere: Node3D
var enemies: Array[CharacterBody3D] = []
var alive_count := 0
var weapons: RefCounted
var player: CharacterBody3D
var viewmodel: CanvasLayer
var hud: Control
var audio: AudioStreamPlayer
var health := 100
var phase := "loading"
var hit_feedback := 0.0
var damage_feedback := 0.0
var random := RandomNumberGenerator.new()
var impacts: Array[Dictionary] = []
var impact_cursor := 0
var shot_count := 0

func _ready() -> void:
    random.randomize()
    var region := NavigationRegion3D.new()
    region.navigation_mesh = load("res://data/navigation.res")
    add_child(region)
    player = CharacterBody3D.new()
    player.set_script(Player)
    player.game = self
    player.name = "Player"
    add_child(player)
    player.position = Vector3(1.15, .05, -3)
    viewmodel = CanvasLayer.new()
    viewmodel.set_script(Viewmodel)
    viewmodel.game = self
    add_child(viewmodel)
    var layer := CanvasLayer.new()
    layer.layer = 10
    layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(layer)
    hud = Control.new()
    hud.set_script(HUD)
    hud.game = self
    layer.add_child(hud)
    audio = AudioStreamPlayer.new()
    audio.set_script(ShotAudio)
    add_child(audio)
    _reset_weapons()
    director = Survival.new()
    director.game = self
    add_child(director)
    melee = load("res://melee.gd").new()
    melee.game = self
    add_child(melee)
    fx = load("res://feedback.gd").new()
    fx.game = self
    add_child(fx)
    atmosphere = load("res://atmosphere.gd").new()
    atmosphere.game = self
    add_child(atmosphere)
    for i in range(24):
        var mark := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = .026
        mesh.height = .052
        mesh.radial_segments = 6
        mesh.rings = 3
        mark.mesh = mesh
        var material := StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.albedo_color = Color(.86, .72, .47)
        mark.material_override = material
        mark.visible = false
        add_child(mark)
        impacts.append({"node": mark, "ttl": 0.0})
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    # Region upload is asynchronous; an initial map iteration can still be empty.
    var map: RID = get_world_3d().navigation_map
    while NavigationServer3D.map_get_iteration_id(map) == 0 or not NavigationServer3D.map_get_closest_point_owner(map, player.position).is_valid():
        await get_tree().physics_frame
    await director.preload_roster()
    phase = "ready"
    print("FIRST_CONTACT_READY")

func _reset_weapons() -> void:
    weapons = WeaponState.new()
    weapons.weapon_changed.connect(viewmodel.equip)
    weapons.reload_started.connect(viewmodel.reload_weapon)
    viewmodel.equip(0)

func start_run() -> void:
    if phase == "loading": return
    get_tree().paused = false
    health = 100
    phase = "running"
    shot_count = 0
    hit_feedback = 0
    damage_feedback = 0
    player.position = Vector3(1.15, .05, -3)
    player.rotation = Vector3.ZERO
    player.velocity = Vector3.ZERO
    player.camera.rotation = Vector3.ZERO
    player.camera.position.y = 1.66
    player.shake = 0
    player.camera.fov = 75
    player.fire_pressed = false
    player.aiming = false
    _reset_weapons()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    for enemy in enemies:
        if is_instance_valid(enemy):
            enemy.set_physics_process(false)
            enemy.collision_layer = 0
            enemy.collision_mask = 0
            enemy.queue_free()
    enemies.clear()
    alive_count = 0
    director.reset()
    melee.reset()
    fx.reset()

func enemy_killed(_enemy: CharacterBody3D) -> void:
    alive_count -= 1
    director.kills += 1

func finish_run() -> void:
    phase = "won"
    weapons.cancel_reload()
    player.fire_pressed = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func pause_run() -> void:
    if phase != "running": return
    phase = "paused"
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func quit_run() -> void:
    get_tree().paused = false
    phase = "quitting"
    audio.stop()
    fx.stop_all()
    await get_tree().create_timer(.08,true,false,true).timeout
    get_tree().quit()

func resume_run() -> void:
    if phase != "paused": return
    phase = "running"
    get_tree().paused = false
    player.fire_pressed = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func take_damage(amount: int) -> void:
    if phase != "running": return
    health = maxi(0, health - amount)
    damage_feedback = .3
    player.shake = .025
    if health == 0:
        phase = "dead"
        player.camera.position.y = 1.35
        player.camera.rotation.z = -.12
        weapons.cancel_reload()
        player.fire_pressed = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func shoot() -> bool:
    if phase != "running" or melee.remaining>0 or not weapons.fire():
        return false
    shot_count += 1
    viewmodel.fire()
    audio.play_shot(weapons.spec().id)
    fx.shot()
    var camera: Camera3D = player.camera
    var origin := camera.global_position
    var forward := -camera.global_basis.z
    var spec: Dictionary = weapons.spec()
    var local_muzzle: Vector3 = viewmodel.muzzle.position + viewmodel.pivot.position
    var world_muzzle: Vector3 = camera.global_transform * local_muzzle
    var guard := PhysicsRayQueryParameters3D.create(origin, world_muzzle, 1)
    var blocked := get_world_3d().direct_space_state.intersect_ray(guard)
    for pellet in range(int(spec.pellets)):
        var direction := forward
        if spec.pellets > 1:
            var spread := float(spec.spread) * (.6 if player.aiming else 1.0)
            direction = (forward + camera.global_basis.x * random.randf_range(-spread, spread) + camera.global_basis.y * random.randf_range(-spread, spread)).normalized()
        var hit := blocked
        if hit.is_empty():
            var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * float(spec.range), 1 | 4)
            hit = get_world_3d().direct_space_state.intersect_ray(query)
        if hit.is_empty():
            continue
        _impact(hit.position)
        if hit.collider.has_method("take_damage"):
            var damage := float(spec.damage)
            if hit.position.y > hit.collider.global_position.y + 1.35:
                damage *= 1.6
            hit.collider.take_damage(damage)
            hit_feedback = .15
    return true

func _impact(point: Vector3) -> void:
    var item: Dictionary = impacts[impact_cursor]
    impact_cursor = (impact_cursor + 1) % impacts.size()
    item.node.global_position = point
    item.node.visible = true
    item.ttl = .12

func _process(delta: float) -> void:
    if director: director.tick(delta)
    for i in range(enemies.size()-1,-1,-1):
        if not is_instance_valid(enemies[i]): enemies.remove_at(i)
    hit_feedback = maxf(0, hit_feedback - delta)
    damage_feedback = maxf(0, damage_feedback - delta)
    for item: Dictionary in impacts:
        if item.ttl > 0:
            item.ttl -= delta
            item.node.visible = item.ttl > 0
