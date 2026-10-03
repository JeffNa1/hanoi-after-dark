extends SceneTree
var failures: Array = []
func _init() -> void: _run.call_deferred()
func _run() -> void:
    var audio := AudioStreamPlayer.new()
    audio.set_script(load("res://shot_audio.gd"))
    root.add_child(audio)
    for id in ["pistol","ak","m4","shotgun"]:
        var sound: AudioStream = audio.shots[id]
        if not sound.resource_path.begins_with("res://assets/audio/"): failures.append(id+": still procedural")
        if sound.get_length() < .3 or sound.get_length() > 1.3: failures.append(id+": invalid recorded-shot length")
        audio.play_shot(id)
        await create_timer(.04).timeout
        if not audio.playing: failures.append(id+": playback did not start")
        await audio.finished
    audio.queue_free()
    await process_frame
    print("RECORDED_AUDIO_TEST ",JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
    quit(0 if failures.is_empty() else 1)
