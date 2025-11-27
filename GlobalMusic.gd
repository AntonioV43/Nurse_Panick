# GlobalMusic.gd (Script Autoload Anda)

extends Node

# Mendapatkan referensi ke node AudioStreamPlayer
@onready var bg_music_player = $"."

# Variabel untuk menampung Stream (file musik)
const MUSIC_GAME = preload("res://phonk-music-440134.mp3") 
# PASTIKAN PATH INI BENAR

func play_game_music():
	# 1. Pastikan stream musik diatur
	bg_music_player.stream = MUSIC_GAME
	
	# 2. Mulai putar musik
	bg_music_player.play()
	
func stop_music():
	bg_music_player.stop()
