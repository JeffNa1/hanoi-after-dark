extends Control
var game: Node
var primary: Button
var secondary: Button
var font: Font

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    font = ThemeDB.fallback_font
    primary = Button.new()
    primary.custom_minimum_size = Vector2(260, 48)
    primary.pressed.connect(func():
        if game.phase == "paused": game.resume_run()
        else: game.start_run())
    add_child(primary)
    secondary = Button.new()
    secondary.text = "QUIT"
    secondary.custom_minimum_size = Vector2(260, 40)
    secondary.pressed.connect(game.quit_run)
    add_child(secondary)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M:
            game.fx.toggle_music()
        elif event.keycode == KEY_ESCAPE:
            if game.phase == "running": game.pause_run()
            elif game.phase == "paused": game.resume_run()
        elif event.keycode == KEY_ENTER and game.phase in ["ready", "dead", "won"]:
            game.start_run()

func _process(_delta: float) -> void:
    var overlay: bool = game.phase != "running"
    primary.visible = overlay
    primary.disabled = game.phase == "loading"
    secondary.visible = overlay
    primary.text = "RESUME" if game.phase == "paused" else ("PLAY AGAIN" if game.phase in ["dead", "won"] else "ENTER STREET")
    if game.phase == "loading": primary.text = "LOADING STREETS"
    primary.position = Vector2(size.x * .5 - 130, size.y * .5 + 66)
    primary.size = Vector2(260, 48)
    secondary.position = primary.position + Vector2(0, 60)
    secondary.size = Vector2(260, 40)
    queue_redraw()

func text_at(value: String, point: Vector2, size_px: int, color: Color = Color.WHITE) -> void:
    draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(value: String, y: float, size_px: int, color: Color = Color.WHITE) -> void:
    var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    text_at(value, Vector2((size.x - width) * .5, y), size_px, color)

func _draw() -> void:
    if not game or not game.weapons:
        return
    var cream := Color(.94, .91, .81)
    var dark := Color(.055, .065, .07, .87)
    draw_rect(Rect2(22, 22, 275, 84), dark)
    text_at("HANOI / AFTER DARK", Vector2(36, 45), 18, cream)
    text_at("WAVE %d / 3   THREATS %d" % [game.director.wave,game.alive_count+game.director.pending], Vector2(36, 69), 14, Color(.78, .8, .72))
    text_at("%02d:%02d   KILLS %d" % [int(game.director.elapsed)/60,int(game.director.elapsed)%60,game.director.kills], Vector2(36, 91), 13, Color(.68,.72,.72))
    draw_rect(Rect2(22, size.y - 88, 190, 60), dark)
    text_at("HEALTH", Vector2(36, size.y - 63), 13, cream)
    text_at(str(game.health), Vector2(131, size.y - 43), 30, Color(.9, .35, .27) if game.health < 30 else cream)
    draw_rect(Rect2(36, size.y - 49, 78, 7), Color(.2, .22, .22))
    draw_rect(Rect2(36, size.y - 49, 78 * float(game.health) / 100, 7), Color(.67, .79, .54))
    var index: int = game.weapons.current
    draw_rect(Rect2(size.x - 252, size.y - 110, 230, 82), dark)
    text_at(str(game.weapons.spec().label), Vector2(size.x - 233, size.y - 82), 17, cream)
    text_at(str(game.weapons.ammo[index]), Vector2(size.x - 234, size.y - 45), 34, cream)
    text_at("/ " + str(game.weapons.reserve[index]), Vector2(size.x - 161, size.y - 47), 20, Color(.65, .7, .7))
    text_at("R  RELOAD", Vector2(size.x - 120, size.y - 81), 11, Color(.65, .7, .7))
    text_at("WASD MOVE   SHIFT RUN   SPACE JUMP   RMB AIM   LMB FIRE   F CROWBAR   1-4 WEAPONS   ESC PAUSE", Vector2(22, size.y - 10), 12, cream)
    if game.phase == "running":
        var center := size * .5
        if game.director.intermission>0:
            centered("STREET QUIET  /  NEXT WAVE IN %d" % ceili(game.director.intermission),size.y*.23,22,cream)
            centered("+20 HEALTH   /   AMMUNITION RESUPPLIED",size.y*.23+26,14,Color(.65,.8,.65))
        var gap := 5.0 if game.player.aiming else 10.0
        var hit: bool = game.hit_feedback > 0
        var color := Color(1, .35, .25) if hit else Color(1, 1, 1, .85)
        for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
            draw_line(center + direction * gap, center + direction * (gap + 5), color, 1.5)
        if hit:
            for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
                draw_line(center + direction * 5, center + direction * 10, color, 2)
        if game.weapons.reload_remaining > 0:
            centered("RELOADING", size.y * .63, 15, cream)
        if game.damage_feedback > 0:
            draw_rect(Rect2(Vector2.ZERO, size), Color(.5, .02, .01, game.damage_feedback * .35))
    else:
        draw_rect(Rect2(Vector2.ZERO, size), Color(.018, .026, .025, .8))
        var title := "AFTER DARK"
        var subtitle := "Survive three waves. Watch the alleys. Keep moving."
        if game.phase == "dead":
            title = "YOU FELL"
            subtitle = "%d threats stopped. Survived %d seconds." % [game.director.kills,int(game.director.elapsed)]
        elif game.phase == "won":
            title = "STREET CLEARED"
            subtitle = "All 27 threats stopped. Survived %d seconds." % int(game.director.elapsed)
        elif game.phase == "paused":
            title = "PAUSED"
            subtitle = "The world is stopped."
        centered("H A N O I", size.y * .5 - 105, 18, Color(.73, .77, .6))
        centered(title, size.y * .5 - 45, 44, cream)
        centered(subtitle, size.y * .5, 17, Color(.67, .73, .72))
        centered("WASD move  /  mouse look  /  RMB aim  /  LMB fire  /  R reload", size.y * .5 + 30, 14, cream)
