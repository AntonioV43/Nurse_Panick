extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	var music_scene = load("res://bg_music.tscn").instantiate()
	get_tree().root.add_child(music_scene)
	get_tree().change_scene_to_file("res://Scene/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/How.tscn")
