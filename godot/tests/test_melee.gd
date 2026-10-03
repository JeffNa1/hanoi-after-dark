extends SceneTree
var game: Node
var failures: Array = []
func _init() -> void: run.call_deferred()
func frames(n: int) -> void:
    for i in range(n): await process_frame
func check(ok: bool, why: String) -> void:
    if not ok: failures.append(why)
func run() -> void:
    root.unfocusable = true
    game = load("res://FPS.tscn").instantiate()
    root.add_child(game)
    while game.phase=="loading": await process_frame
    var wrench: Node3D = game.get_node("WorkshopWrench")
    check(wrench.visible and wrench.position.y<.3,"Licensed wrench rests on the measured street surface")
    game.start_run()
    game.set_process(false)
    var enemy := CharacterBody3D.new()
    enemy.set_script(game.Zombie)
    enemy.game = game
    enemy.model_key = "vn_zombie_16_sua_xe"
    enemy.position = game.player.position+Vector3(0,0,-1.2)
    game.add_child(enemy)
    enemy.set_physics_process(false)
    game.enemies.append(enemy)
    game.alive_count = 1
    await frames(5)
    var ammunition: int = game.weapons.ammo[0]
    var input := InputEventKey.new()
    input.physical_keycode = KEY_F
    input.keycode = KEY_F
    input.pressed = true
    Input.parse_input_event(input)
    await frames(2)
    input.pressed = false
    Input.parse_input_event(input)
    check(game.melee.remaining>0,"F starts the licensed crowbar strike")
    check(not game.shoot(),"Gunfire cannot overlap melee")
    check(not game.melee.start(),"Melee cannot bypass its cooldown")
    await frames(15)
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://../evidence/crowbar_contact.png")
    await frames(30)
    check(enemy.health==40 and game.melee.hits==1,"One strike removes 40 health exactly once")
    check(game.weapons.ammo[0]==ammunition,"Emergency melee needs no ammunition")
    var wall := StaticBody3D.new()
    wall.collision_layer = 1
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(2,3,.1)
    collision.shape = box
    wall.add_child(collision)
    wall.position = game.player.position+Vector3(0,1.2,-.6)
    game.add_child(wall)
    await frames(4)
    game.melee.start()
    await frames(46)
    check(enemy.health==40,"Crowbar cannot damage through a wall")
    wall.queue_free()
    await frames(4)
    game.melee.start()
    await frames(46)
    check(enemy.dead and game.director.kills==1,"Lethal strike counts one death")
    game.take_damage(100)
    check(not game.melee.start(),"Dead player cannot strike")
    game.start_run()
    check(game.melee.remaining==0 and not game.melee.grip.visible,"Restart clears melee presentation and cooldown")
    var report := {"passed":failures.is_empty(),"failures":failures,"nativeInput":true,"assets":["Poly Haven Crowbar 01 CC0","LonesomeDucky Adjustable Wrench CC0"]}
    FileAccess.open("res://../reports/melee.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("MELEE_TEST ",JSON.stringify(report))
    await preload("res://tests/cleanup.gd").finish(self,game)
    quit(0 if failures.is_empty() else 1)
