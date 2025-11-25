extends Node3D

# Skrip ini membuat node menghadap kamera setiap frame.
# Pasang ke Node3D (mis. MeshInstance3D, Sprite3D, dll).
# Jika only_y_axis = true maka node hanya akan berputar pada sumbu Y (tidak miring/tilt).

@export var only_y_axis: bool = true

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var cam_pos: Vector3 = camera.global_transform.origin

	if only_y_axis:
		# Hitung arah ke kamera tapi hilangkan komponen Y agar tidak mentilt
		var dir: Vector3 = cam_pos - global_transform.origin
		dir.y = 0
		if dir.length_squared() > 0.000001:
			# look_at() mengharapkan target point; kita pakai posisi + arah tanpa Y
			look_at(global_transform.origin + dir, Vector3.UP)
	else:
		# Menghadap ke posisi kamera penuh (termasuk pitch)
		look_at(cam_pos, Vector3.UP)
