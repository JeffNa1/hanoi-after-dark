extends Node
## Licensed crowbar quick strike. The grip stays below the view frame.
var game: Node
var grip: Node3D
var remaining := 0.0
var applied := false
var swings := 0
var hits := 0

func _ready() -> void:
    grip = Node3D.new()
    game.viewmodel.viewport.add_child(grip)
    var crowbar: Node3D = load("res://assets/melee/crowbar/crowbar.gltf").instantiate()
    crowbar.position.y = .348
    crowbar.scale = Vector3.ONE*1.176
    grip.add_child(crowbar)
    grip.visible = false
    var wrench: Node3D = load("res://assets/melee/wrench.glb").instantiate()
    wrench.name = "WorkshopWrench"
    wrench.position = Vector3(2.85,.2,-10.3)
    wrench.rotation_degrees = Vector3(0,20,0)
    wrench.visible = false
    game.add_child(wrench)
    await get_tree().physics_frame
    var floor_ray := PhysicsRayQueryParameters3D.create(wrench.position+Vector3.UP*2,wrench.position-Vector3.UP*2,1)
    var floor_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(floor_ray)
    assert(not floor_hit.is_empty(),"Workshop detail needs the actual street surface")
    wrench.position.y = floor_hit.position.y+.01
    wrench.visible = true

func reset() -> void:
    remaining = 0
    applied = false
    swings = 0
    hits = 0
    grip.visible = false
    game.viewmodel.model.visible = true

func start() -> bool:
    if game.phase!="running" or remaining>0: return false
    game.weapons.cancel_reload()
    remaining = .72
    applied = false
    swings += 1
    game.fx.swing()
    game.player.fire_pressed = false
    game.viewmodel.flash_time = 0
    return true

func strike() -> void:
    var best: CharacterBody3D = null
    var distance := 1.65
    var camera: Camera3D = game.player.camera
    var origin: Vector3 = game.player.global_position+Vector3.UP
    var forward := -camera.global_basis.z
    forward.y = 0
    forward = forward.normalized()
    for enemy in game.enemies:
        if not is_instance_valid(enemy) or enemy.dead: continue
        var offset: Vector3 = enemy.global_position-game.player.global_position
        offset.y = 0
        if offset.length()>=distance or offset.normalized().dot(forward)<.65: continue
        var ray := PhysicsRayQueryParameters3D.create(origin,enemy.global_position+Vector3.UP,1|4)
        var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
        if not hit.is_empty() and hit.collider==enemy:
            best = enemy
            distance = offset.length()
    if best:
        best.take_damage(40)
        game.hit_feedback = .18
        hits += 1

func _process(delta: float) -> void:
    if game.phase!="running":
        grip.visible = false
        return
    if remaining<=0:
        game.viewmodel.model.visible = true
        grip.visible = false
        return
    remaining = maxf(0,remaining-delta)
    var time := .72-remaining
    grip.visible = true
    game.viewmodel.model.visible = false
    var swing := smoothstep(.16,.30,time)
    var return_amount := smoothstep(.36,.72,time)
    grip.position = Vector3(lerpf(.40,.20,swing),-.57,-.61)
    grip.rotation = Vector3(.05+sin(time/.72*PI)*.2,0,lerpf(lerpf(-.4,1.1,swing),.35,return_amount))
    if not applied and time>=.26:
        applied = true
        strike()
