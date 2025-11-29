extends Node3D

# --- KONFIGURASI WAKTU (Dari kode lama kamu) ---
@export var waktu_pintu_1: float = 10.0
@export var waktu_pintu_2: float = 10.0
@export var waktu_pintu_3: float = 10.0
@export var waktu_pintu_4: float = 10.0

# --- REFERENSI ALAT ---
@onready var timer_1 = $Timer_1
@onready var timer_2 = $Timer_2
@onready var timer_3 = $Timer_3
@onready var timer_4 = $Timer_4

@onready var teks_1 = $Teks_Pintu_1
@onready var teks_2 = $Teks_Pintu_2
@onready var teks_3 = $Teks_Pintu_3
@onready var teks_4 = $Teks_Pintu_4

@onready var ui_label = $CanvasLayer/Label_Interaksi 

# --- INGATAN ---
var pasien_di_pintu_1 = null
var pasien_di_pintu_2 = null
var pasien_di_pintu_3 = null
var pasien_di_pintu_4 = null

var game_manager = null

# --- DEFINISI WARNA RUANGAN ---
var warna_ruangan = {
	1: "merah",
	2: "biru",
	3: "hijau",
	4: "kuning"
}

func _ready():
	# spawner untuk lapor skor
	var managers = get_tree().get_nodes_in_group("spawner") # Pastikan spawner ada di grup 'spawner' atau 'game_manager'
	if not managers.is_empty():
		game_manager = managers[0]
	else:
		# Fallback ke grup game_manager jika spawner tidak ketemu
		var gm = get_tree().get_nodes_in_group("game_manager")
		if not gm.is_empty(): game_manager = gm[0]

	ui_label.visible = false 
	
	# Set Teks Awal (Menunjukkan Warna Ruangan)
	reset_teks_ruangan(1, teks_1)
	reset_teks_ruangan(2, teks_2)
	reset_teks_ruangan(3, teks_3)
	reset_teks_ruangan(4, teks_4)

func _process(delta):
	# Update timer (Teks jadi putih saat menghitung)
	if not timer_1.is_stopped(): teks_1.text = str(ceil(timer_1.time_left)); teks_1.modulate = Color.RED
	if not timer_2.is_stopped(): teks_2.text = str(ceil(timer_2.time_left)); teks_2.modulate = Color.RED
	if not timer_3.is_stopped(): teks_3.text = str(ceil(timer_3.time_left)); teks_3.modulate = Color.RED
	if not timer_4.is_stopped(): teks_4.text = str(ceil(timer_4.time_left)); teks_4.modulate = Color.RED

# --- FUNGSI BANTUAN UI ---
func tampilkan_ui(pesan):
	ui_label.text = pesan
	ui_label.visible = true

func sembunyikan_ui():
	ui_label.visible = false

# --- LOGIKA INPUT ---
func _input(event):
	if event.is_action_pressed("send"):
		proses_interaksi(1, pasien_di_pintu_1, timer_1, teks_1, waktu_pintu_1)
		proses_interaksi(2, pasien_di_pintu_2, timer_2, teks_2, waktu_pintu_2)
		proses_interaksi(3, pasien_di_pintu_3, timer_3, teks_3, waktu_pintu_3)
		proses_interaksi(4, pasien_di_pintu_4, timer_4, teks_4, waktu_pintu_4)

# ⭐ LOGIKA PENGECEKAN WARNA (JANTUNG PERMAINAN) ⭐
func proses_interaksi(no_pintu, pasien, timer, teks, waktu_durasi: float):
	if pasien != null and timer.is_stopped():
		
		# 1. AMBIL WARNA
		var warna_baju = pasien.patient_type # Dari script patient.gd
		var warna_kamar = warna_ruangan[no_pintu]
		
		print("Cek: Pasien %s masuk Kamar %s" % [warna_baju, warna_kamar])
		
		# 2. CEK KECOCOKAN
		if warna_baju == warna_kamar:
			# --- JIKA BENAR (SUKSES) ---
			pasien.queue_free() 
			
			# Mulai Timer
			timer.wait_time = waktu_durasi
			timer.start()
			
			# Lapor ke Spawner (Sukses)
			if game_manager and game_manager.has_method("patient_successfully_processed"):
				game_manager.patient_successfully_processed()
				
			teks.modulate = Color.RED # Merah tanda sedang sibuk/operasi
			
		else:
			# --- JIKA SALAH (GAGAL) ---
			print("SALAH KAMAR! Pasien Meninggal.")
			pasien.queue_free()
			
			# Lapor ke Spawner (Gagal/Mati)
			if game_manager and game_manager.has_method("patient_failed_to_process"):
				game_manager.patient_failed_to_process()
			
			# Timer TIDAK dimulai, kembalikan teks ruangan
			reset_teks_ruangan(no_pintu, teks)

		# Reset ingatan di pintu ini
		if no_pintu == 1: pasien_di_pintu_1 = null
		elif no_pintu == 2: pasien_di_pintu_2 = null
		elif no_pintu == 3: pasien_di_pintu_3 = null
		elif no_pintu == 4: pasien_di_pintu_4 = null
		
		sembunyikan_ui()

# Fungsi Helper: Mengembalikan nama ruangan dan warnanya
func reset_teks_ruangan(no_pintu, label):
	var warna = warna_ruangan[no_pintu]
	label.text = "RUANG " + warna.to_upper()
	
	if warna == "merah": label.modulate = Color(1, 0.2, 0.2)
	elif warna == "biru": label.modulate = Color(0.4, 0.4, 1)
	elif warna == "hijau": label.modulate = Color(0.2, 1, 0.2)
	elif warna == "kuning": label.modulate = Color(1, 1, 0.2)

# --- SENSOR EVENTS ---
func _on_sensor_1_body_entered(body): if body.is_in_group("pasien"): pasien_di_pintu_1 = body; tampilkan_ui("[F] Masukkan Pasien")
func _on_sensor_2_body_entered(body): if body.is_in_group("pasien"): pasien_di_pintu_2 = body; tampilkan_ui("[F] Masukkan Pasien")
func _on_sensor_3_body_entered(body): if body.is_in_group("pasien"): pasien_di_pintu_3 = body; tampilkan_ui("[F] Masukkan Pasien")
func _on_sensor_4_body_entered(body): if body.is_in_group("pasien"): pasien_di_pintu_4 = body; tampilkan_ui("[F] Masukkan Pasien")

func _on_sensor_1_body_exited(body): if body == pasien_di_pintu_1: pasien_di_pintu_1 = null; sembunyikan_ui()
func _on_sensor_2_body_exited(body): if body == pasien_di_pintu_2: pasien_di_pintu_2 = null; sembunyikan_ui()
func _on_sensor_3_body_exited(body): if body == pasien_di_pintu_3: pasien_di_pintu_3 = null; sembunyikan_ui()
func _on_sensor_4_body_exited(body): if body == pasien_di_pintu_4: pasien_di_pintu_4 = null; sembunyikan_ui()

# --- TIMER TIMEOUTS (Reset ke nama ruangan) ---
func _on_timer_1_timeout(): reset_teks_ruangan(1, teks_1)
func _on_timer_2_timeout(): reset_teks_ruangan(2, teks_2)
func _on_timer_3_timeout(): reset_teks_ruangan(3, teks_3)
func _on_timer_4_timeout(): reset_teks_ruangan(4, teks_4)
