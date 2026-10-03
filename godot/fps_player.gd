extends CharacterBody3D
var game: Node
var camera: Camera3D
var aiming := false
var fire_pressed := false
var mouse_sway := Vector2.ZERO
var shake := 0.0
var shake_clock := 0.0
const WALK_SPEED := 3.4

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1 | 4
    floor_snap_length = .25
    var capsule := CapsuleShape3D.new()
    capsule.radius = .27
    capsule.height = 1.7
    var shape := CollisionShape3D.new()
    shape.shape = capsule
    shape.position.y = .86
    add_child(shape)
    camera = Camera3D.new()
    camera.position.y = 1.66
    camera.current = true
    camera.fov = 75
    camera.near = .05
    camera.far = 500
    add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if game.phase != "running":
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotation.y -= event.relative.x * .0022
        camera.rotation.x = clampf(camera.rotation.x - event.relative.y * .0022, -1.35, 1.35)
        mouse_sway = event.relative.limit_length(25) * .001
    if event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            return
        if event.button_index == MOUSE_BUTTON_LEFT:
            fire_pressed = true
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            game.weapons.equip(posmod(game.weapons.current - 1, game.weapons.DEFINITIONS.size()))
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            game.weapons.equip(posmod(game.weapons.current + 1, game.weapons.DEFINITIONS.size()))
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_F:
            game.melee.start()
        elif event.physical_keycode == KEY_R and game.melee.remaining<=0:
            game.weapons.start_reload()
        elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4 and game.melee.remaining<=0:
            game.weapons.equip(event.physical_keycode - KEY_1)

func _physics_process(delta: float) -> void:
    if game.phase != "running":
        return
    aiming = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and game.weapons.reload_remaining <= 0
    shake_clock += delta
    shake = maxf(0,shake-delta*.12)
    camera.rotation.z = sin(shake_clock*37)*shake
    var axis := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
    var direction := (basis * Vector3(axis.x, 0, axis.y)).normalized()
    var speed := WALK_SPEED
    if aiming:
        speed *= .65
    elif Input.is_physical_key_pressed(KEY_SHIFT):
        speed *= 1.65
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    velocity.y -= 19 * delta
    if is_on_floor() and Input.is_physical_key_pressed(KEY_SPACE):
        velocity.y = 4.2
    move_and_slide()
    if position.y < -4:
        game.take_damage(200)
    game.weapons.tick(delta)
    var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    if fire_pressed or (held and game.weapons.spec().automatic):
        game.shoot()
    fire_pressed = false
    camera.fov = lerpf(camera.fov, 54.0 if aiming else 75.0, minf(1.0, delta * 13))
    mouse_sway = mouse_sway.lerp(Vector2.ZERO, minf(1.0, delta * 9))
