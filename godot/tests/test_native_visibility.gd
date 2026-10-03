extends SceneTree
func _init() -> void: _run.call_deferred()
func frames(count: int) -> void:
    for i in range(count): await process_frame
func _run() -> void:
    root.unfocusable=true
    var game: Node=load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    game.start_run()
    for enemy in game.enemies: enemy.set_physics_process(false)
    var rows: Array=[]
    var passed:=true
    for index in range(4):
        game.weapons.equip(index)
        await frames(30)
        await RenderingServer.frame_post_draw
        var before: Image=game.viewmodel.viewport.get_texture().get_image()
        before.convert(Image.FORMAT_RGBA8)
        var original: PackedByteArray=before.get_data()
        var visible_pixels:=0
        for i in range(3,original.size(),4):
            if original[i]>32: visible_pixels+=1
        var registered:=true
        for mesh: MeshInstance3D in game.viewmodel.model.find_children("*","MeshInstance3D",true,false):
            if mesh.skin and mesh.get_skin_reference()==null: registered=false
        var fired: bool=game.shoot()
        await frames(60)
        var reloaded: bool=game.weapons.start_reload()
        await frames(int(game.weapons.spec().reload*60*.45))
        await RenderingServer.frame_post_draw
        var after: Image=game.viewmodel.viewport.get_texture().get_image()
        after.convert(Image.FORMAT_RGBA8)
        var changed:=0
        var data: PackedByteArray=after.get_data()
        for i in range(3,original.size(),4):
            if abs(int(original[i])-int(data[i]))>32: changed+=1
        var ok: bool=visible_pixels>10000 and changed>1000 and registered and fired and reloaded
        passed=passed and ok
        rows.append({"weapon":game.weapons.spec().id,"visiblePixels":visible_pixels,"changedReloadPixels":changed,"gpuSkinRegistered":registered,"passed":ok})
        game.weapons.cancel_reload()
    var report:={"passed":passed,"weapons":rows,"scope":"Native GPU alpha coverage, registered render skins and actual reload silhouette changes; no artistic approval claim."}
    FileAccess.open("res://../reports/native_visibility.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("NATIVE_VISIBILITY_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if passed else 1)
