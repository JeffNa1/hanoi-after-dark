extends CanvasLayer
## A separate native viewport is the standard FPS viewmodel projection.
var game: Node
var animator: AnimationPlayer
var model: Node3D
var pivot: Node3D
var viewport: SubViewport
var camera: Camera3D
var muzzle: MeshInstance3D
var muzzle_light: OmniLight3D
var flash_time := 0.0
var walk_phase := 0.0
var metadata: Dictionary

func _ready() -> void:
    layer = 4
    metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/viewmodels.json"))
    var container := SubViewportContainer.new()
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    container.stretch = true
    add_child(container)
    viewport = SubViewport.new()
    viewport.size = Vector2i(1280, 720)
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.handle_input_locally = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    container.add_child(viewport)
    camera = Camera3D.new()
    camera.fov = 65
    camera.near = .012
    camera.far = 5
    viewport.add_child(camera)
    camera.current = true
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_CLEAR_COLOR
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color(.55, .62, .72)
    world.environment.ambient_light_energy = .50
    viewport.add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    light.light_color = Color(.94, .79, .60)
    light.light_energy = .75
    viewport.add_child(light)
    pivot = Node3D.new()
    viewport.add_child(pivot)
    muzzle = MeshInstance3D.new()
    var flash := SphereMesh.new()
    flash.radius = .028
    flash.height = .056
    flash.radial_segments = 8
    flash.rings = 4
    muzzle.mesh = flash
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(1, .76, .22)
    muzzle.material_override = mat
    muzzle.visible = false
    pivot.add_child(muzzle)
    muzzle_light = OmniLight3D.new()
    muzzle_light.omni_range = 1.3
    muzzle_light.light_color = Color(1, .68, .20)
    muzzle_light.light_energy = 0
    pivot.add_child(muzzle_light)

func equip(index: int) -> void:
    if model:
        pivot.remove_child(model)
        model.queue_free()
    var id: String = game.weapons.DEFINITIONS[index].id
    model = load("res://assets/" + id + ".glb").instantiate()
    pivot.add_child(model)
    animator = model.find_children("*", "AnimationPlayer", true, false)[0]
    animator.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
    animator.animation_finished.connect(_animation_finished)
    animator.play("idle")
    animator.advance(0)
    var m: Array = metadata[id].muzzle_godot
    muzzle.position = Vector3(m[0], m[1], m[2])
    muzzle_light.position = muzzle.position
    flash_time = 0

func fire() -> void:
    animator.stop()
    var speed := 1.0
    if game.weapons.spec().shell_reload:
        speed = animator.get_animation("fire").length / float(game.weapons.spec().interval)
    animator.play("fire", -1, speed)
    flash_time = .045

func reload_weapon(_index: int) -> void:
    animator.stop()
    animator.play("reload", -1, animator.get_animation("reload").length / float(game.weapons.spec().reload))

func _animation_finished(_name: StringName) -> void:
    animator.play("idle")

func _process(delta: float) -> void:
    if not model:
        return
    flash_time = maxf(0, flash_time - delta)
    muzzle.visible = flash_time > 0
    muzzle_light.light_energy = 1.8 if flash_time > 0 else 0.0
    if game.phase != "running":
        return
    var aim: bool = game.player.aiming
    var id: String = game.weapons.spec().id
    var a: Array = metadata[id].ads_offset_godot
    var target := Vector3(a[0], a[1], a[2]) if aim else Vector3.ZERO
    var speed: float = Vector2(game.player.velocity.x, game.player.velocity.z).length()
    if speed > .1:
        walk_phase += delta * speed * 2.8
        target += Vector3(sin(walk_phase) * .009, absf(cos(walk_phase)) * .006, 0) * (.25 if aim else 1.0)
    target += Vector3(-game.player.mouse_sway.x, game.player.mouse_sway.y, 0) * (.35 if aim else 1)
    var start: Vector3 = game.player.camera.global_position
    var front := PhysicsRayQueryParameters3D.create(start, start - game.player.camera.global_basis.z * .9, 1)
    if not game.player.get_world_3d().direct_space_state.intersect_ray(front).is_empty():
        target.y -= .17
        target.z += .10
    pivot.position = pivot.position.lerp(target, minf(1, delta * 14))
    camera.fov = lerpf(camera.fov, 58.0 if aim else 65.0, minf(1, delta * 13))
