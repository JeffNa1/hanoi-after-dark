extends AudioStreamPlayer
## Licensed recorded one-shots. Source identities and edits are in the credits.
var shots: Dictionary = {}

func _ready() -> void:
    volume_db = -10
    max_polyphony = 6
    for id in ["pistol", "ak", "m4", "shotgun"]:
        shots[id] = load("res://assets/audio/" + id + ".wav")

func play_shot(id: String) -> void:
    if stream != shots[id]: stream = shots[id]
    play()
