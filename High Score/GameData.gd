extends Node

# Variabel ini akan hidup terus selama game menyala
var high_score: int = 0

# Fungsi untuk cek dan update high score
func update_high_score(current_score: int):
	if current_score > high_score:
		high_score = current_score
