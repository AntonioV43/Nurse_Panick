extends CSGBox3D

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("npc"):
		# NPC bisa tembus tembok
		body.set_collision_mask(0)
		body.set_collision_layer(0)

func _on_body_exited(body):
	if body.is_in_group("npc"):
		# Kembalikan collider NPC setelah keluar dari tembok
		body.set_collision_mask(1)
		body.set_collision_layer(1)
