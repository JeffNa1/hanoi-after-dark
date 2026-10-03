extends Node3D
## Bounded recorded-audio and particle pools. No per-shot resource loading.
var game: Node
var clips: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var particles: Array[CPUParticles3D] = []
var voice_cursor := 0
var particle_cursor := 0
var music: AudioStreamPlayer
var foley: AudioStreamPlayer
var steps: Array[AudioStream] = []
var step_cursor := 0
var step_distance := 0.0
var groan_wait := 4.0
var events := {"spawn":0,"pain":0,"death":0,"step":0,"swing":0,"shot":0}
var muted := false
var muzzle_light: OmniLight3D
var muzzle_time := 0.0

func _ready() -> void:
    for id in ["growl_a","growl_b","pain","death","crowbar"]:
        clips[id] = load("res://assets/audio/survival/"+id+".wav")
    for id in ["L1","R1","L2","R2"]:
        steps.append(load("res://assets/audio/survival/step_"+id+".ogg"))
    music = AudioStreamPlayer.new()
    music.stream = load("res://assets/audio/survival/ambience.ogg")
    music.stream.loop = true
    music.volume_db = -24
    add_child(music)
    music.play()
    foley = AudioStreamPlayer.new()
    foley.volume_db = -20
    foley.max_polyphony = 3
    add_child(foley)
    for i in range(8):
        var voice := AudioStreamPlayer3D.new()
        voice.unit_size = 5
        voice.max_distance = 32
        voice.volume_db = -15
        voice.max_db = -8
        add_child(voice)
        voices.append(voice)
        var burst := CPUParticles3D.new()
        burst.emitting = false
        burst.one_shot = true
        burst.amount = 12
        burst.lifetime = .42
        burst.explosiveness = 1
        burst.spread = 65
        burst.initial_velocity_min = .7
        burst.initial_velocity_max = 1.8
        burst.gravity = Vector3(0,-5,0)
        burst.direction = Vector3.UP
        var mesh := SphereMesh.new()
        mesh.radius = .025
        mesh.height = .05
        mesh.radial_segments = 4
        mesh.rings = 2
        burst.mesh = mesh
        var material := StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.vertex_color_use_as_albedo = true
        burst.material_override = material
        add_child(burst)
        particles.append(burst)
    muzzle_light = OmniLight3D.new()
    muzzle_light.omni_range = 6
    muzzle_light.light_color = Color(1,.63,.24)
    muzzle_light.light_energy = 0
    add_child(muzzle_light)

func reset() -> void:
    for voice in voices: voice.stop()
    for burst in particles: burst.emitting = false
    for key in events: events[key] = 0
    step_distance = 0
    groan_wait = 4
    muzzle_time = 0
    muzzle_light.light_energy = 0

func _exit_tree() -> void:
    stop_all()

func stop_all() -> void:
    music.stop()
    foley.stop()
    for voice in voices: voice.stop()

func sound(id: String, point: Vector3, volume: float = -15) -> void:
    var voice := voices[voice_cursor]
    voice_cursor = (voice_cursor+1)%voices.size()
    voice.stop()
    voice.stream = clips[id]
    voice.global_position = point
    voice.pitch_scale = randf_range(.94,1.04)
    voice.volume_db = volume
    voice.play()

func burst(point: Vector3, blood: bool) -> void:
    var effect := particles[particle_cursor]
    particle_cursor = (particle_cursor+1)%particles.size()
    effect.global_position = point
    effect.color = Color(.38,.025,.018) if blood else Color(.5,.4,.26)
    effect.scale_amount_min = .4 if blood else .15
    effect.scale_amount_max = 1.0 if blood else .4
    effect.restart()
    effect.emitting = true

func spawn_cue(point: Vector3) -> void:
    events.spawn += 1
    sound("growl_a" if events.spawn%2==0 else "growl_b",point,-16)
    burst(point+Vector3.UP*.15,false)

func enemy_hit(point: Vector3, lethal: bool) -> void:
    events["death" if lethal else "pain"] += 1
    sound("death" if lethal else "pain",point,-14 if lethal else -18)
    burst(point+Vector3.UP,true)

func swing() -> void:
    events.swing += 1
    foley.stream = clips.crowbar
    foley.volume_db = -17
    foley.play()

func shot() -> void:
    events.shot += 1
    muzzle_time = .045
    muzzle_light.global_position = game.player.camera.global_position-game.player.camera.global_basis.z*.35
    game.player.shake = minf(.014,game.player.shake+.006)

func toggle_music() -> void:
    muted = not muted

func _process(delta: float) -> void:
    muzzle_time = maxf(0,muzzle_time-delta)
    muzzle_light.light_energy = 3.5 if muzzle_time>0 else 0
    music.volume_db = lerpf(music.volume_db,-80.0 if muted else (-22.0 if game.phase=="running" else -28.0),minf(1,delta*3))
    if game.phase!="running": return
    var speed := Vector2(game.player.velocity.x,game.player.velocity.z).length()
    if game.player.is_on_floor() and speed>.15:
        step_distance += speed*delta
        if step_distance>1.65:
            step_distance = 0
            foley.stream = steps[step_cursor]
            step_cursor = (step_cursor+1)%steps.size()
            foley.volume_db = -20
            foley.play()
            events.step += 1
    groan_wait -= delta
    if groan_wait<=0:
        groan_wait = randf_range(3.5,6)
        for enemy in game.enemies:
            if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(game.player.global_position)<18:
                sound("growl_b",enemy.global_position,-21)
                break
