extends SceneTree
const WeaponState = preload("res://weapon_state.gd")
var failures: Array = []

func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func finish() -> void:
    print("WEAPON_STATE_TEST ", JSON.stringify({"passed": failures.is_empty(), "failures": failures}))
    quit(0 if failures.is_empty() else 1)

func _init() -> void:
    var state = WeaponState.new()
    if not state.fire():
        check(false, "A loaded pistol must fire")
        finish()
        return
    check(state.ammo[0] == 11, "One shot consumes one round")
    check(not state.fire(), "Cooldown prevents extra shots")
    state.tick(.3)
    check(state.fire(), "Pistol fires after cooldown")
    check(state.start_reload(), "Partial magazine can reload")
    check(not state.fire(), "Magazine reload blocks firing")
    state.tick(2.0)
    check(state.ammo[0] == 12 and state.reserve[0] == 70, "Reload conserves ammunition")
    check(not state.start_reload(), "A full magazine cannot reload")
    state.ammo[0] = 0
    state.reserve[0] = 2
    check(not state.fire(), "Empty magazine cannot fire")
    check(state.start_reload(), "Low reserve permits partial refill")
    state.tick(2.0)
    check(state.ammo[0] == 2 and state.reserve[0] == 0, "Reload never invents rounds")
    state.cancel_reload()
    finish()
