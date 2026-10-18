extends Node

const SAVE_PATH := "user://local_save.json"
var player := {
    "nickname": "LocalPlayer",
    "gold": 1000,
    "stage": 1,
    "unit_level": 1,
    "total_kills": 0
}

func _ready() -> void:
    load_state()

func load_state() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        player.merge(parsed, true)

func save_state() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(player))

func reward_for_stage() -> int:
    return 100 + int(player.stage * 25)

func clear_stage() -> int:
    var reward := reward_for_stage()
    player.gold += reward
    player.stage += 1
    player.total_kills += 10
    save_state()
    return reward

func enhance_unit() -> bool:
    var cost: int = 200 + (player.unit_level - 1) * 100
    if player.gold < cost:
        return false
    player.gold -= cost
    player.unit_level += 1
    save_state()
    return true
