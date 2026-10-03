extends RefCounted
## Fixed-fps headless tests outrun the real audio thread; drain stopped playback before exit.
static func finish(tree: SceneTree, game: Node) -> void:
    tree.paused = false
    game.phase = "ready"
    game.audio.stop()
    game.fx.stop_all()
    OS.delay_msec(ceili(AudioServer.get_time_to_next_mix()*1000)+60)
    await tree.process_frame
    game.queue_free()
    await tree.process_frame
    await tree.process_frame
