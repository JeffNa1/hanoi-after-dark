extends SceneTree
func _init() -> void:
    _run.call_deferred()
func _run() -> void:
    var failures: Array = []
    if not ResourceLoader.exists("res://data/navigation.res"):
        failures.append("Baked obstacle-aware navigation is required")
    if not ResourceLoader.exists("res://zombie.gd"):
        failures.append("Animated encounter is required")
    print("ENCOUNTER_PREREQUISITES ", JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
    quit(0 if failures.is_empty() else 1)
