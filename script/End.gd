extends Control

@onready var label_status = $Label # Label "Game Over" / "YOU WIN!"
@onready var label_pasien = $Label2 # Label "Pasien Selamat = ?"
@onready var button_restart = $VBoxContainer/Button # Button "Restart"
@onready var button_exit = $VBoxContainer/Button3 # Button "Exit"

# --- FUNGSI BARU/DIMODIFIKASI UNTUK MENAMPILKAN DATA AKHIR ---
func set_end_screen_data(is_win: bool, saved_count: int, failed_count: int, max_count: int):
	if is_win:
		label_status.text = "YOU WIN!"
		label_status.modulate = Color.GREEN
	else:
		label_status.text = "GAME OVER"
		label_status.modulate = Color.RED
	
	# Menampilkan data
	label_pasien.text = "Pasien Selamat: " + str(saved_count) + "\n" + \
						"Pasien Meninggal: " + str(failed_count) + "\n" + \
						"Total Pasien: " + str(max_count)

func _ready():
	# Hubungkan sinyal tombol saat scene siap
	process_mode = Node.PROCESS_MODE_ALWAYS
	button_restart.pressed.connect(_on_restart_pressed)
	button_exit.pressed.connect(_on_exit_pressed)

func _on_restart_pressed():
	# Ganti dengan scene game utama Anda, cek kembali path folder
	var main_game_path = "res://Scene/main.tscn" 
	
	# Tambahkan print debug untuk melihat apakah fungsi dipanggil dan path benar
	print("Mencoba me-restart game ke path:", main_game_path) 
	
	if FileAccess.file_exists(main_game_path):
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# Pindah Scene
		var error = get_tree().change_scene_to_file(main_game_path)
		if error == OK:
			call_deferred("queue_free")
			print("Scene berhasil dipindah. End Menu akan dihapus.")
		else:
			push_error("Gagal memuat scene: " + str(error))
	else:
		push_error("Main Game Scene tidak ditemukan di jalur: " + main_game_path)


func _on_exit_pressed():
	print("Keluar dari Game")
	get_tree().quit()
