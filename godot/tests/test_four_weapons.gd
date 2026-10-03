extends SceneTree
const State = preload("res://weapon_state.gd")
var failures: Array = []
func _init() -> void:
    var state = State.new()
    if state.DEFINITIONS.size() != 4:
        failures.append("Four distinct selectable weapon definitions are required")
    else:
        for index in range(4):
            if index > 0: state.equip(index)
            state.tick(1)
            var capacity: int = state.spec().capacity
            if not state.fire() or state.ammo[index] != capacity - 1: failures.append("Fire failed: " + str(index))
            if state.fire(): failures.append("Fire cooldown bypassed")
            state.tick(1)
            if not state.start_reload(): failures.append("Reload failed")
            state.tick(float(state.spec().reload) + .01)
            if state.ammo[index] != capacity: failures.append("Reload missing ammunition")
        state.equip(3)
        state.tick(1)
        state.fire()
        state.tick(1)
        state.fire()
        state.tick(1)
        state.start_reload()
        state.tick(float(state.spec().reload) + .01)
        if state.ammo[3] != 5 or state.reload_remaining <= 0: failures.append("Shotgun must load individual shells")
        if not state.fire() or state.reload_remaining != 0: failures.append("Shotgun reload must allow fire interruption")
        state.equip(1)
        if not state.spec().automatic: failures.append("AK must support held trigger")
        state.equip(2)
        if not state.spec().automatic: failures.append("M4 must support held trigger")
    print("FOUR_WEAPONS_TEST ", JSON.stringify({"passed": failures.is_empty(), "failures": failures}))
    quit(0 if failures.is_empty() else 1)
