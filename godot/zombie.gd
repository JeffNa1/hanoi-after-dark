extends CharacterBody3D
const WALK_SPEED := 1.35
const RUN_SPEED := 2.7
var game: Node
var model_key := "zombie"
var health := 80.0
var dead := false
var agent: NavigationAgent3D
var animator: AnimationPlayer
var repath := 0.0
var attack_time := -1.0
var attack_target := Vector3.ZERO
var attack_applied := false
var flinch := 0.0
var corpse_time := 0.0
var animation_clock := 0.0

func _ready() -> void:
    collision_layer = 4
    collision_mask = 1 | 2 | 4
    floor_snap_length = .3
    var capsule := CapsuleShape3D.new()
    capsule.radius = .30
    capsule.height = 1.72
    var shape := CollisionShape3D.new()
    shape.shape = capsule
    shape.position.y = .87
    add_child(shape)
    var visual: Node3D = load("res://assets/"+model_key+".glb").instantiate()
    add_child(visual)
    animator = visual.find_children("*","AnimationPlayer",true,false)[0]
    for clip in ["idle", "walk", "run"]:
        animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
    var skeleton: Skeleton3D = visual.find_children("*","Skeleton3D",true,false)[0]
    var planting: SkeletonModifier3D = load("res://foot_plant.gd").new()
    skeleton.add_child(planting)
    planting.setup(self)
    agent = NavigationAgent3D.new()
    agent.path_desired_distance = .30
    # Baked floor samples are at y=.33; the collider feet rest near y=-.03.
    agent.path_height_offset = .35
    agent.target_desired_distance = 1.05
    agent.radius = .3
    agent.height = 1.72
    add_child(agent)
    play("idle")

func play(clip: String, speed: float = 1.0) -> void:
    if animator.current_animation != clip:
        animator.play(clip, .10, speed)
        # Start a short first support step from idle, not a full rear extension.
        if clip=="walk": animator.seek(.36,true)

func clear_swing(target: Vector3) -> bool:
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target + Vector3.UP, 1)
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_damage(amount: float) -> void:
    if dead: return
    animator.speed_scale = 1.0
    health = maxf(0, health - amount)
    game.fx.enemy_hit(global_position,health==0)
    if health == 0:
        dead = true
        collision_layer = 0
        collision_mask = 0
        velocity = Vector3.ZERO
        animator.play("death", .07)
        game.enemy_killed(self)
    else:
        flinch = .28
        attack_time = -1
        # Imported reactions have different lengths; finish within the gameplay flinch.
        animator.play("hit", .04, animator.get_animation("hit").length / flinch)
        # play() resumes an already-playing clip; a new impact needs a new reaction.
        animator.seek(0,true)

func _physics_process(delta: float) -> void:
    animation_clock += delta
    if dead:
        corpse_time += delta
        if corpse_time > 7: queue_free()
        return
    if game.phase != "running":
        velocity = Vector3.ZERO
        animator.speed_scale = 1.0
        play("idle")
        return
    velocity.y -= 19 * delta
    var offset: Vector3 = game.player.global_position - global_position
    offset.y = 0
    velocity.x = 0
    velocity.z = 0
    var locomotion := false
    animator.speed_scale = 1.0
    if flinch > 0:
        flinch -= delta
    elif attack_time >= 0:
        attack_time += delta
        if not attack_applied and attack_time >= .55:
            attack_applied = true
            var escaped: Vector3 = game.player.global_position - attack_target
            escaped.y = 0
            if escaped.length() < .85 and offset.length() < 1.8 and clear_swing(game.player.global_position):
                game.take_damage(18)
        if attack_time >= 1.22: attack_time = -1
    elif offset.length() < 1.5 and clear_swing(game.player.global_position):
        attack_time = 0
        attack_applied = false
        attack_target = game.player.global_position
        rotation.y = atan2(offset.x, offset.z)
        animator.play("attack", .08, 2.2)
    else:
        locomotion = true
        repath -= delta
        if repath <= 0:
            agent.target_position = game.player.global_position
            repath = .3
        if not agent.is_navigation_finished():
            var direction := agent.get_next_path_position() - global_position
            direction.y = 0
            direction = direction.normalized()
            # Keep the original walk pace; sprint pursuit makes the run clip reachable.
            var target_speed := Vector2(game.player.velocity.x,game.player.velocity.z).length()
            var speed := RUN_SPEED if target_speed>4.5 and offset.length()>4 else WALK_SPEED
            velocity.x = direction.x * speed
            velocity.z = direction.z * speed
            rotation.y = lerp_angle(rotation.y, atan2(direction.x,direction.z), minf(1,delta*8))
    var before_move := global_position
    move_and_slide()
    if locomotion:
        var moved := global_position - before_move
        var actual_speed := Vector2(moved.x, moved.z).length() / delta
        if actual_speed > .02:
            var clip := "run" if actual_speed>2.0 else "walk"
            play(clip)
            # The authored walk travels 1.08m per 1.2s cycle at native speed.
            animator.speed_scale = actual_speed / (RUN_SPEED if clip=="run" else .9)
        else:
            play("idle")
