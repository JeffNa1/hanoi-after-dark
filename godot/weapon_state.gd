extends RefCounted
## Gameplay ammunition lifecycle; presentation and hit detection stay outside.
signal reload_started(index: int)
signal reload_completed(index: int)
signal weapon_changed(index: int)
const DEFINITIONS := [
    {"id":"pistol", "label":"PISTOL", "capacity":12, "reserve":72, "damage":28.0, "interval":.28, "reload":1.5, "automatic":false, "pellets":1, "spread":.003, "range":90.0, "shell_reload":false},
    {"id":"ak", "label":"AK-STYLE", "capacity":30, "reserve":150, "damage":24.0, "interval":.115, "reload":2.1, "automatic":true, "pellets":1, "spread":.010, "range":120.0, "shell_reload":false},
    {"id":"m4", "label":"M4-STYLE", "capacity":30, "reserve":150, "damage":20.0, "interval":.085, "reload":1.9, "automatic":true, "pellets":1, "spread":.006, "range":120.0, "shell_reload":false},
    {"id":"shotgun", "label":"SHOTGUN", "capacity":6, "reserve":36, "damage":13.0, "interval":.85, "reload":1.2, "automatic":false, "pellets":8, "spread":.065, "range":45.0, "shell_reload":true}
]
var current := 0
var ammo: Array[int] = []
var reserve: Array[int] = []
var cooldown := 0.0
var reload_remaining := 0.0

func _init() -> void:
    for definition: Dictionary in DEFINITIONS:
        ammo.append(int(definition.capacity))
        reserve.append(int(definition.reserve))

func spec() -> Dictionary:
    return DEFINITIONS[current]

func fire() -> bool:
    if cooldown > 0 or ammo[current] <= 0:
        return false
    if reload_remaining > 0:
        if not spec().shell_reload:
            return false
        cancel_reload()
    ammo[current] -= 1
    cooldown = float(spec().interval)
    return true

func start_reload() -> bool:
    if reload_remaining > 0 or ammo[current] >= int(spec().capacity) or reserve[current] <= 0:
        return false
    reload_remaining = float(spec().reload)
    reload_started.emit(current)
    return true

func cancel_reload() -> void:
    reload_remaining = 0.0

func equip(index: int) -> bool:
    if index < 0 or index >= DEFINITIONS.size() or index == current:
        return false
    cancel_reload()
    current = index
    cooldown = .22
    weapon_changed.emit(current)
    return true

func tick(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if reload_remaining <= 0:
        return
    reload_remaining -= delta
    if reload_remaining > 0:
        return
    var needed := int(spec().capacity) - ammo[current]
    var amount := mini(needed, reserve[current])
    if spec().shell_reload:
        amount = mini(amount, 1)
    ammo[current] += amount
    reserve[current] -= amount
    reload_remaining = 0.0
    reload_completed.emit(current)
    if spec().shell_reload and ammo[current] < int(spec().capacity) and reserve[current] > 0:
        start_reload()
