extends Node

## O'yin progressi va darajalar ochilishini boshqaruvchi Autoload (LevelProgressManager).
## Ma'lumotlar user://progress.cfg fayliga ConfigFile orqali saqlanadi.

const PROGRESS_PATH: String = "user://progress.cfg"

var unlocked_level: int = 1
var run_score: int = 0
var run_enemies_defeated: int = 0
var _level_scores: Dictionary = {}
var _level_kills: Dictionary = {}


func _ready() -> void:
	load_progress()


func is_level_unlocked(level_index: int) -> bool:
	return level_index <= unlocked_level


func unlock_level(level_index: int) -> void:
	if level_index > unlocked_level:
		unlocked_level = clampi(level_index, 1, 3)
		save_progress()


func start_new_run() -> void:
	run_score = 0
	run_enemies_defeated = 0
	_level_scores.clear()
	_level_kills.clear()


func commit_level_result(level_index: int, level_score: int, level_kills: int) -> void:
	_level_scores[level_index] = maxi(int(_level_scores.get(level_index, 0)), level_score)
	_level_kills[level_index] = maxi(int(_level_kills.get(level_index, 0)), level_kills)

	var total_s: int = 0
	var total_k: int = 0
	for k in _level_scores.keys():
		total_s += int(_level_scores[k])
		total_k += int(_level_kills.get(k, 0))

	run_score = total_s
	run_enemies_defeated = total_k


func get_total_score() -> int:
	return run_score


func get_total_enemies_defeated() -> int:
	return run_enemies_defeated


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_level", unlocked_level)
	config.save(PROGRESS_PATH)


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PROGRESS_PATH) != OK:
		unlocked_level = 1
		return
	unlocked_level = clampi(int(config.get_value("progress", "unlocked_level", 1)), 1, 3)
