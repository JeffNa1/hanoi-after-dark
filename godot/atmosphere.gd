extends Node3D
## Street-wide dusk atmosphere with a bounded pool of nearby practical lights.
var game: Node
var points: Array[Vector3] = []
var lights: Array[OmniLight3D] = []
var refresh := 0.0
var clock := 0.0
var flashlight: SpotLight3D
func _ready() -> void:
    var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/street_layout.json"))
    for road: Dictionary in layout.roads:
        var start := Vector3(road.a[0],3.4,-road.a[1])
        var end := Vector3(road.b[0],3.4,-road.b[1])
        var length := start.distance_to(end)
        for distance in range(9,int(length),18):
            points.append(start.lerp(end,float(distance)/length))
    for i in range(8):
        var light := OmniLight3D.new()
        light.omni_range = 8
        light.omni_attenuation = 1.25
        light.light_color = Color(1,.56,.26)
        light.light_energy = 1.3
        light.shadow_enabled = false
        add_child(light)
        lights.append(light)
    flashlight = SpotLight3D.new()
    flashlight.spot_range = 19
    flashlight.spot_angle = 34
    flashlight.spot_angle_attenuation = 1.2
    flashlight.light_color = Color(.84,.90,1)
    flashlight.light_energy = .85
    flashlight.shadow_enabled = true
    flashlight.position = Vector3(.1,-.12,.06)
    game.player.camera.add_child(flashlight)
    var layer := CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    var tint := ColorRect.new()
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material := ShaderMaterial.new()
    material.shader = load("res://atmosphere.gdshader")
    tint.material = material
    layer.add_child(tint)

func _process(delta: float) -> void:
    clock += delta
    refresh -= delta
    if refresh<=0:
        refresh = 1.0
        var position: Vector3 = game.player.global_position
        points.sort_custom(func(a: Vector3,b: Vector3) -> bool: return a.distance_squared_to(position)<b.distance_squared_to(position))
        for i in range(lights.size()): lights[i].global_position = points[i]
    for i in range(lights.size()):
        var distance := lights[i].global_position.distance_to(game.player.global_position)
        lights[i].light_energy = (1.28+sin(clock*1.7+i)*.055)*clampf((32-distance)/12,0,1)
