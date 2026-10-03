extends SceneTree
func _init() -> void: _run.call_deferred()
func _run() -> void:
    var failures: Array=[]
    var rows: Array=[]
    for name in ["pistol","ak","m4","shotgun","zombie","vn_zombie_12_xiec_lua","vn_zombie_15_tiktoker","vn_zombie_16_sua_xe","vn_zombie_17_duong_sinh"]:
        var scene: Node=load("res://assets/"+name+".glb").instantiate()
        root.add_child(scene)
        var count:=0
        for mesh: MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
            if not mesh.skin: continue
            count+=1
            if mesh.skeleton.is_empty() or not (mesh.get_node_or_null(mesh.skeleton) is Skeleton3D): failures.append(name+"/"+mesh.name+" has no render skeleton")
        rows.append({"model":name,"skinnedMeshes":count})
        scene.queue_free()
        await process_frame
    print("RENDER_BINDINGS_TEST ",JSON.stringify({"passed":failures.is_empty(),"rows":rows,"failures":failures}))
    quit(0 if failures.is_empty() else 1)
