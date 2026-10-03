extends SkeletonModifier3D
## Native two-bone leg IK with world-space support targets.
var actor: Node
var skeleton: Skeleton3D
var feet: Array = []
var previous_clip := ""


class FootOrientation extends SkeletonModifier3D:
    var tracker: Node
    func _process_modification() -> void:
        tracker.match_orientation()

func setup(body: Node) -> void:
    actor = body
    skeleton = get_skeleton()
    for side in ["l","r"]:
        var target := Node3D.new()
        add_child(target)
        target.top_level = true
        var pole := Node3D.new()
        add_child(pole)
        pole.top_level = true
        var solver := TwoBoneIK3D.new()
        skeleton.add_child(solver)
        solver.set_setting_count(1)
        solver.set_root_bone_name(0,"thigh_"+side)
        solver.set_middle_bone_name(0,"calf_"+side)
        solver.set_end_bone_name(0,"foot_"+side)
        solver.set_target_node(0,solver.get_path_to(target))
        solver.set_pole_node(0,solver.get_path_to(pole))
        solver.influence = 0
        feet.append({"bone":skeleton.find_bone("foot_"+side),"target":target,"pole":pole,"solver":solver,"locked":false,"plant":Transform3D.IDENTITY,"offset":0.0 if side=="l" else .5})
    var orientation := FootOrientation.new()
    orientation.tracker = self
    skeleton.add_child(orientation)

func _process_modification() -> void:
    if not actor: return
    var clip: String = actor.animator.current_animation
    var walking: bool = clip=="walk" and not actor.dead
    var standing: bool = clip=="idle" and not actor.dead

    if clip!=previous_clip:
        for foot in feet: foot.locked=false
    previous_clip=clip
    if standing:
        var pelvis := skeleton.find_bone("pelvis")
        var pose := skeleton.get_bone_global_pose(pelvis)
        pose.origin.y -= .075
        skeleton.set_bone_global_pose(pelvis,pose)
        # Carry-preserving source idles can be static. Breathe above the planted feet
        # without moving the actor, replacing its assets, or breaking hand/tool grips.
        var chest := skeleton.find_bone("spine_03")
        var chest_pose := skeleton.get_bone_global_pose(chest)
        chest_pose.basis *= Basis(Vector3.RIGHT,sin(actor.animation_clock*TAU/2.4)*.07)
        skeleton.set_bone_global_pose(chest,chest_pose)
    for foot in feet:
        var enabled: bool = actor.is_on_floor() and (standing or walking)
        foot.solver.influence = 1.0 if enabled else 0.0
        if not enabled:
            foot.locked=false
            continue
        var current := skeleton.global_transform * skeleton.get_bone_global_pose(foot.bone)
        var phase := fposmod(actor.animator.current_animation_position/1.2+foot.offset,1.0) if walking else 0.0
        var support: bool = standing or phase<.62 or phase>=.94
        if support:
            if not foot.locked:
                foot.plant=current
                var rest := skeleton.global_transform * skeleton.get_bone_global_rest(foot.bone)
                foot.plant.origin.y=rest.origin.y+.012
                foot.plant.basis=rest.basis
                foot.locked=true
            foot.target.global_transform=foot.plant
        else:
            var blend := smoothstep(.62,.79,phase)
            var swing: Transform3D=foot.plant.interpolate_with(current,blend)
            swing.origin.y=current.origin.y
            foot.target.global_transform=swing
            foot.locked=false
        foot.pole.global_position=actor.global_position+actor.global_basis*Vector3(0,.55,1.2)

func match_orientation() -> void:
    for foot in feet:
        if foot.solver.influence<=0: continue
        var pose := skeleton.get_bone_global_pose(foot.bone)
        pose.basis=skeleton.global_basis.inverse()*foot.target.global_basis
        skeleton.set_bone_global_pose(foot.bone,pose)
