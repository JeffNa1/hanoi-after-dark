extends RefCounted
## Independent CPU skinning of occupied sole vertices, not bone origins or AABBs.
var skeleton: Skeleton3D
var samples := {"l": [], "r": []}
var bindings: Array = []
var final_measurement: Dictionary = {}
func _init(model: Node3D) -> void:
    skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        if not mesh.skin: continue
        var bind_offset := bindings.size()
        for i in range(mesh.skin.get_bind_count()):
            var bone := mesh.skin.get_bind_bone(i)
            if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(i))
            bindings.append({"bone":bone,"inverse":mesh.skin.get_bind_pose(i)})
        for surface in range(mesh.mesh.get_surface_count()):
            var arrays := mesh.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
            var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
            var count := joints.size()/vertices.size()
            for i in range(vertices.size()):
                var rest := Vector3.ZERO
                var sides := {"l":0.0,"r":0.0}
                var influences: Array = []
                for j in range(count):
                    var weight: float = weights[i*count+j]
                    if weight <= .00001: continue
                    var bind: int = joints[i*count+j]+bind_offset
                    var name: String = skeleton.get_bone_name(bindings[bind].bone)
                    rest += skeleton.get_bone_global_rest(bindings[bind].bone) * bindings[bind].inverse * vertices[i] * weight
                    influences.append([bind,weight])
                    for side in ["l","r"]:
                        if name.ends_with("_"+side) and (name.begins_with("foot") or name.begins_with("ball")):
                            sides[side] += weight
                for side in ["l","r"]:
                    if sides[side] > .7 and rest.y < .018:
                        samples[side].append({"point":vertices[i],"influences":influences})
    skeleton.skeleton_updated.connect(_capture_final_pose)
func _capture_final_pose() -> void:
    final_measurement = _measure_now()
func measure() -> Dictionary:
    return final_measurement if not final_measurement.is_empty() else _measure_now()
func _measure_now() -> Dictionary:
    var transforms: Array[Transform3D] = []
    for binding in bindings:
        transforms.append(skeleton.global_transform * skeleton.get_bone_global_pose(binding.bone) * binding.inverse)
    var result := {}
    for side in ["l","r"]:
        var mean := Vector3.ZERO
        var low := INF
        var high := -INF
        for sample in samples[side]:
            var point := Vector3.ZERO
            for influence in sample.influences:
                point += transforms[influence[0]] * sample.point * influence[1]
            mean += point
            low = minf(low,point.y)
            high = maxf(high,point.y)
        mean /= max(1,samples[side].size())
        result[side] = {"centroid":mean,"low":low,"high":high,"vertices":samples[side].size()}
    return result
