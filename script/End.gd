extends Control

# Referensi Node (Sesuaikan dengan nama node di scene menu kamu)
@onready var label_status = $Label 
@onready var label_pasien = $Label2 
@onready var button_restart = $VBoxContainer/Button 
@onready var button_exit = $VBoxContainer/Button3 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Sambungkan tombol (jika belum via editor)
	if not button_restart.pressed.is_connected(_on_restart_pressed):
		button_restart.pressed.connect(_on_restart_pressed)
	if not button_exit.pressed.is_connected(_on_exit_pressed):
		button_exit.pressed.connect(_on_exit_pressed)

# --- FUNGSI UTAMA: MENERIMA DATA DARI SPAWNER ---
func set_end_screen_data(is_win: bool, saved_count: int, failed_count: int, total_spawned: int):
	if is_win:
		label_status.text = "YOU WIN!"
		label_status.modulate = Color.GREEN
		# Pesan Menang
		label_pasien.text = "Perfect! You saved all patients."
	else:
		label_status.text = "GAME OVER"
		label_status.modulate = Color.RED
		
		# Pesan Kalah 
		label_pasien.text = "You lost " + str(failed_count) + " patients."

func _on_restart_pressed():
	get_tree().paused = false
	var main_game_path = "res://Scene/main.tscn"
	
	if FileAccess.file_exists(main_game_path):
		get_tree().change_scene_to_file(main_game_path)
	else:
		get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()
