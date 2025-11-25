extends Node3D

# --- WAKTU TIMER YANG BISA DISET DI INSPECTOR ---
# Gunakan @export var untuk mengatur nilai waktu (float)
@export var waktu_pintu_1: float = 10.0 # Default 10 detik
@export var waktu_pintu_2: float = 10.0 # Default 10 detik
@export var waktu_pintu_3: float = 10.0 # Default 10 detik
@export var waktu_pintu_4: float = 10.0 # Default 10 detik

# --- REFERENSI ALAT (KEMBALI KE CHILD NODE) ---
# Timer tetap merujuk ke child node seperti semula
@onready var timer_1 = $Timer_1
@onready var timer_2 = $Timer_2
@onready var timer_3 = $Timer_3
@onready var timer_4 = $Timer_4

@onready var teks_1 = $Teks_Pintu_1
@onready var teks_2 = $Teks_Pintu_2
@onready var teks_3 = $Teks_Pintu_3
@onready var teks_4 = $Teks_Pintu_4

# REFERENSI UI INTERAKSI BARU (Tambahan)
@onready var ui_label = $CanvasLayer/Label_Interaksi 

# --- INGATAN (PASIEN DI MANA?) ---
var pasien_di_pintu_1 = null
var pasien_di_pintu_2 = null
var pasien_di_pintu_3 = null
var pasien_di_pintu_4 = null

var game_manager = null

func _ready():
	var managers = get_tree().get_nodes_in_group("game_manager")
	if not managers.is_empty():
		game_manager = managers[0]
		print("DEBUG: Game Manager ditemukan oleh Hospital.")
	else:
		push_warning("ERROR: Game Manager/Spawner tidak ditemukan! Fitur end-game tidak akan berfungsi.")

	# Sembunyikan UI Interaksi saat game dimulai
	ui_label.visible = false 
	# Set semua tulisan awal jadi hijau
	teks_1.text = "EMPTY"; teks_1.modulate = Color.GREEN
	teks_2.text = "EMPTY"; teks_2.modulate = Color.GREEN
	teks_3.text = "EMPTY"; teks_3.modulate = Color.GREEN
	teks_4.text = "EMPTY"; teks_4.modulate = Color.GREEN

func _process(delta):
	# Update angka hitung mundur JIKA timer sedang jalan
	if not timer_1.is_stopped(): teks_1.text = str(ceil(timer_1.time_left))
	if not timer_2.is_stopped(): teks_2.text = str(ceil(timer_2.time_left))
	if not timer_3.is_stopped(): teks_3.text = str(ceil(timer_3.time_left))
	if not timer_4.is_stopped(): teks_4.text = str(ceil(timer_4.time_left))

# --- FUNGSI BANTUAN UI BARU ---
func tampilkan_ui(pesan):
	ui_label.text = pesan
	ui_label.visible = true

func sembunyikan_ui():
	ui_label.visible = false

# --- LOGIKA INPUT (TOMBOL F) ---
func _input(event):
	if event.is_action_pressed("send"):
		proses_interaksi(1, pasien_di_pintu_1, timer_1, teks_1, waktu_pintu_1) # Tambahkan waktu_pintu_1
		proses_interaksi(2, pasien_di_pintu_2, timer_2, teks_2, waktu_pintu_2) # Tambahkan waktu_pintu_2
		proses_interaksi(3, pasien_di_pintu_3, timer_3, teks_3, waktu_pintu_3) # Tambahkan waktu_pintu_3
		proses_interaksi(4, pasien_di_pintu_4, timer_4, teks_4, waktu_pintu_4) # Tambahkan waktu_pintu_4

# Fungsi khusus biar kita ga nulis kode berulang-ulang
# Tambahkan parameter baru 'waktu_durasi'
func proses_interaksi(no_pintu, pasien, timer, teks, waktu_durasi: float):
	if pasien != null and timer.is_stopped():
		pasien.queue_free() # Hapus pasien
		
		# Reset ingatan variabel global (PENTING)
		if no_pintu == 1: pasien_di_pintu_1 = null
		elif no_pintu == 2: pasien_di_pintu_2 = null
		elif no_pintu == 3: pasien_di_pintu_3 = null
		elif no_pintu == 4: pasien_di_pintu_4 = null
		
		# Set dan mulai Timer dengan nilai yang di-export
		timer.wait_time = waktu_durasi
		timer.start()
		
		teks.modulate = Color.RED
		sembunyikan_ui() # Sembunyikan UI setelah pasien dimasukkan
		print("Pasien masuk Pintu " + str(no_pintu) + " dengan timer: " + str(waktu_durasi) + " detik.")
		if game_manager and game_manager.has_method("patient_successfully_processed"):
			game_manager.patient_successfully_processed()


# --- LOGIKA SENSOR MASUK (UPDATE UNTUK UI) ---
func _on_sensor_1_body_entered(body): 
	if body.is_in_group("pasien"): 
		pasien_di_pintu_1 = body
		tampilkan_ui("[F] Masukkan Pasien") # Munculkan UI

func _on_sensor_2_body_entered(body): 
	if body.is_in_group("pasien"): 
		pasien_di_pintu_2 = body
		tampilkan_ui("[F] Masukkan Pasien")

func _on_sensor_3_body_entered(body): 
	if body.is_in_group("pasien"): 
		pasien_di_pintu_3 = body
		tampilkan_ui("[F] Masukkan Pasien")

func _on_sensor_4_body_entered(body): 
	if body.is_in_group("pasien"): 
		pasien_di_pintu_4 = body
		tampilkan_ui("[F] Masukkan Pasien")

# --- LOGIKA SENSOR KELUAR (UPDATE UNTUK UI) ---
func _on_sensor_1_body_exited(body): 
	if body == pasien_di_pintu_1: 
		pasien_di_pintu_1 = null
		sembunyikan_ui() # Hilangkan UI

func _on_sensor_2_body_exited(body): 
	if body == pasien_di_pintu_2: 
		pasien_di_pintu_2 = null
		sembunyikan_ui() # Hilangkan UI

func _on_sensor_3_body_exited(body): 
	if body == pasien_di_pintu_3: 
		pasien_di_pintu_3 = null
		sembunyikan_ui() # Hilangkan UI

func _on_sensor_4_body_exited(body): 
	if body == pasien_di_pintu_4: 
		pasien_di_pintu_4 = null
		sembunyikan_ui() # Hilangkan UI

# --- LOGIKA TIMER HABIS ---
func _on_timer_1_timeout(): teks_1.text = "EMPTY"; teks_1.modulate = Color.GREEN
func _on_timer_2_timeout(): teks_2.text = "EMPTY"; teks_2.modulate = Color.GREEN
func _on_timer_3_timeout(): teks_3.text = "EMPTY"; teks_3.modulate = Color.GREEN
func _on_timer_4_timeout(): teks_4.text = "EMPTY"; teks_4.modulate = Color.GREEN
