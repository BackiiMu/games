extends Node

signal state_changed

const SAVE_PATH := "user://local_save.json"
const QUEST_SECONDS := [1, 3, 5, 10, 30, 60, 120]
const QUEST_REWARDS := [20, 156, 270, 436, 1100, 2350, 5000]
const UNIT_COSTS := [200, 500, 1200, 3000]
const RELIC_COST := 750
const BATTLE_INTERVAL := 3.0

var player: Dictionary = _default_player()
var battle_elapsed := 0.0
var autosave_elapsed := 0.0
var persist_enabled := true

func _default_player() -> Dictionary:
    return {
        "nickname": "LocalPlayer", "gold": 1000, "gems": 0, "medals": 0,
        "stage": 1, "unit_level": 1, "total_kills": 0,
        "units": [1], "relics": [], "inventory": [],
        "quest_end": {}, "quest_levels": [1, 0, 0, 0, 0, 0, 0],
        "auto_battle": false, "speed_until": 0, "speed_tier": 2,
        "damage_until": 0, "challenge_next": {},
        "pvp_wins": 0, "pvp_next": 0, "rebirths": 0
    }

func _ready() -> void:
    load_state()

func _process(delta: float) -> void:
    if player.auto_battle:
        battle_elapsed += delta
        var interval: float = BATTLE_INTERVAL / speed_multiplier()
        if battle_elapsed >= interval:
            battle_elapsed -= interval
            clear_stage()
    var completed := false
    var now := Time.get_unix_time_from_system()
    for key in player.quest_end.keys():
        if float(player.quest_end[key]) <= now:
            completed = true
            var index := int(key)
            player.gold += quest_reward(index)
            player.quest_end.erase(key)
    if completed:
        _changed()
    autosave_elapsed += delta
    if autosave_elapsed >= 15.0:
        autosave_elapsed = 0.0
        save_state()

func load_state() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        var defaults := _default_player()
        defaults.merge(parsed, true)
        player = defaults
        if not player.units is Array or player.units.is_empty():
            player.units = [maxi(1, int(player.unit_level))]
        if not player.relics is Array:
            player.relics = []
        if not player.inventory is Array:
            player.inventory = []
        if not player.quest_end is Dictionary:
            player.quest_end = {}
        if not player.quest_levels is Array or player.quest_levels.size() != 7:
            player.quest_levels = [1, 0, 0, 0, 0, 0, 0]
        if not player.challenge_next is Dictionary:
            player.challenge_next = {}

func save_state() -> void:
    if not persist_enabled:
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(player))

func _changed() -> void:
    save_state()
    state_changed.emit()

func is_speed_active() -> bool:
    return int(player.speed_until) > Time.get_unix_time_from_system()

func speed_multiplier() -> float:
    return float(player.speed_tier) if is_speed_active() else 1.0

func reward_for_stage() -> int:
    var power := 0
    for level in player.units:
        power += int(level)
    var amount := 100 + int(player.stage) * 25 + power * 5
    if int(player.damage_until) > Time.get_unix_time_from_system():
        amount = int(amount * 1.5)
    return amount

func clear_stage() -> int:
    var reward := reward_for_stage()
    player.gold += reward
    player.stage += 1
    player.total_kills += 10
    if int(player.stage) % 10 == 0:
        player.medals += 1
    if int(player.stage) % 5 == 0:
        player.gems += 10
    _changed()
    return reward

func set_auto_battle(enabled: bool) -> void:
    player.auto_battle = enabled
    battle_elapsed = 0.0
    _changed()

func unit_cost(index: int = 0) -> int:
    if index < 0 or index >= player.units.size():
        return -1
    return 200 + (int(player.units[index]) - 1) * 100

func enhance_unit(index: int = 0) -> bool:
    var cost := unit_cost(index)
    if cost < 0 or int(player.gold) < cost:
        return false
    player.gold -= cost
    player.units[index] += 1
    player.unit_level = player.units[0]
    _changed()
    return true

func buy_unit() -> bool:
    var index: int = player.units.size()
    if index >= UNIT_COSTS.size() or int(player.gold) < UNIT_COSTS[index]:
        return false
    player.gold -= UNIT_COSTS[index]
    player.units.append(1)
    _changed()
    return true

func quest_reward(index: int) -> int:
    if index < 0 or index >= QUEST_REWARDS.size():
        return 0
    return QUEST_REWARDS[index] * maxi(1, int(player.quest_levels[index]))

func quest_remaining(index: int) -> int:
    return maxi(0, int(ceil(float(player.quest_end.get(str(index), 0)) - Time.get_unix_time_from_system())))

func start_quest(index: int) -> bool:
    if index < 0 or index >= QUEST_SECONDS.size():
        return false
    if index > 0 and int(player.quest_levels[index]) <= 0:
        return false
    if player.quest_end.has(str(index)):
        return false
    player.quest_end[str(index)] = Time.get_unix_time_from_system() + QUEST_SECONDS[index]
    _changed()
    return true

func unlock_quest(index: int) -> bool:
    if index <= 0 or index >= QUEST_SECONDS.size() or int(player.quest_levels[index]) > 0:
        return false
    if int(player.quest_levels[index - 1]) <= 0:
        return false
    var cost := 300 * index
    if int(player.gold) < cost:
        return false
    player.gold -= cost
    player.quest_levels[index] = 1
    _changed()
    return true

func buy_relic() -> bool:
    if player.relics.size() >= 20:
        return false
    if int(player.gold) < RELIC_COST:
        return false
    player.gold -= RELIC_COST
    var relic_id: int = player.relics.size() % 8 + 1
    player.relics.append(relic_id)
    player.inventory.append({"kind": "relic", "id": relic_id})
    _changed()
    return true

func buy_speed() -> bool:
    if int(player.gold) < 500:
        return false
    var keep_three := is_speed_active() and int(player.speed_tier) >= 3
    player.gold -= 500
    player.speed_until = maxi(int(player.speed_until), int(Time.get_unix_time_from_system())) + 1200
    if not keep_three:
        player.speed_tier = 2
    _changed()
    return true

func buy_gem_buff(kind: String) -> bool:
    if kind != "speed3" and kind != "damage":
        return false
    if int(player.gems) < 100:
        return false
    player.gems -= 100
    var until := int(Time.get_unix_time_from_system()) + 1200
    if kind == "speed3":
        player.speed_until = maxi(int(player.speed_until), until)
        player.speed_tier = 3
    else:
        player.damage_until = maxi(int(player.damage_until), until)
    _changed()
    return true

func play_challenge(index: int) -> bool:
    if index < 0 or index > 4:
        return false
    if index == 0:
        return play_local_pvp()
    if int(player.stage) < 5 + index * 5:
        return false
    var key := str(index)
    if int(player.challenge_next.get(key, 0)) > Time.get_unix_time_from_system():
        return false
    player.challenge_next[key] = int(Time.get_unix_time_from_system()) + 60
    player.gold += 200 * index
    player.medals += 2 * index
    _changed()
    return true

func play_local_pvp() -> bool:
    if int(player.stage) < 5:
        return false
    if int(player.pvp_next) > Time.get_unix_time_from_system():
        return false
    var power := 0
    for level in player.units:
        power += int(level)
    if power + int(player.stage) < 7:
        return false
    player.pvp_wins += 1
    player.medals += 5
    player.pvp_next = int(Time.get_unix_time_from_system()) + 30
    _changed()
    return true

func rebirth() -> bool:
    if int(player.stage) < 50:
        return false
    player.medals += int(player.stage) / 10
    player.rebirths += 1
    player.stage = 1
    player.gold = 1000
    player.quest_end.clear()
    player.auto_battle = false
    _changed()
    return true
