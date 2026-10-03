extends Node3D

func _ready() -> void:
    var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/colliders.json"))
    for item: Dictionary in entries:
        var body := StaticBody3D.new()
        body.position = Vector3(item.position[0], item.position[2], -item.position[1])
        body.rotation.y = float(item.yaw)
        body.collision_layer = 1
        body.collision_mask = 0
        var shape := BoxShape3D.new()
        shape.size = Vector3(item.size[0], item.size[2], item.size[1])
        var collision := CollisionShape3D.new()
        collision.shape = shape
        body.add_child(collision)
        add_child(body)
