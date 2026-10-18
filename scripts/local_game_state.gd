extends Node

signal state_changed

const SAVE_PATH := "user://local_save.json"
const QUEST_SECONDS := [1, 3, 5, 10, 30, 60, 120]
const QUEST_REWARDS := [20, 156, 270, 436, 1100, 2350, 5000]
const UNIT_COSTS := [200, 500, 1200, 3000]
const RELIC_COST := 750
const BATTLE_INTERVAL := 1.0
const MAX_OFFLINE_SECONDS := 3600

var player: Dictionary = _default_player()
var battle_elapsed := 0.0
var autosave_elapsed := 0.0
var persist_enabled := true

func _default_player() -> Dictionary:
    return {
        "nickname": "LocalPlayer", "gold": 1000, "gems": 0, "medals": 0,
        "stage": 1, "unit_level": 1, "total_kills": 0,
        "enemy_hp": 12, "hero_hp": 100,
        "units": [1], "relics": [], "inventory": [],
        "equipment": {}, "pets": [], "active_pet": -1,
        "ships": [], "active_ship": -1, "ship_explore_next": 0,
        "guild": {"level": 1, "xp": 0, "raid_next": 0},
        "relic_levels": {}, "shards": 0,
        "tower_floor": 0, "dungeon_tickets": 3, "dungeon_last_refill": 0,
        "achievements": {}, "last_seen_unix": 0,
        "quest_end": {}, "quest_levels": [1, 0, 0, 0, 0, 0, 0],
        "auto_battle": false, "speed_until": 0, "speed_tier": 2,
        "damage_until": 0, "challenge_next": {},
        "pvp_wins": 0, "pvp_next": 0, "rebirths": 0
    }

func _ready() -> void:
    load_state()
    settle_offline()

func _process(delta: float) -> void:
    if player.auto_battle:
        battle_elapsed += delta
        var interval: float = BATTLE_INTERVAL / speed_multiplier()
        if battle_elapsed >= interval:
            battle_elapsed -= interval
            battle_step()
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
        if not parsed.has("enemy_hp"):
            player.enemy_hp = 10 + int(player.stage) * 2
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
        if not player.equipment is Dictionary:
            player.equipment = {}
        if not player.pets is Array:
            player.pets = []
        if not player.ships is Array:
            player.ships = []
        if not player.guild is Dictionary:
            player.guild = {"level": 1, "xp": 0, "raid_next": 0}
        for key in ["level", "xp", "raid_next"]:
            if not player.guild.has(key):
                player.guild[key] = 1 if key == "level" else 0
        if not player.achievements is Dictionary:
            player.achievements = {}
        if not player.relic_levels is Dictionary:
            player.relic_levels = {}
        player.enemy_hp = maxi(1, int(player.enemy_hp))
        player.hero_hp = clampi(int(player.hero_hp), 1, 100)

func save_state() -> void:
    if not persist_enabled:
        return
    player.last_seen_unix = int(Time.get_unix_time_from_system())
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(player))

func _changed() -> void:
    save_state()
    state_changed.emit()

func settle_offline(now_unix: int = -1) -> Dictionary:
    var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
    var elapsed := clampi(now - int(player.last_seen_unix), 0, MAX_OFFLINE_SECONDS) if int(player.last_seen_unix) > 0 else 0
    var stages_before := int(player.stage)
    var gold_before := int(player.gold)
    var changed := false
    if player.auto_battle and elapsed > 0:
        var ticks := mini(int(elapsed * speed_multiplier()), MAX_OFFLINE_SECONDS * 3)
        for i in ticks:
            _battle_step_internal()
        changed = true
    for key in player.quest_end.keys():
        if int(player.quest_end[key]) <= now:
            player.gold += quest_reward(int(key))
            player.quest_end.erase(key)
            changed = true
    if _refill_dungeon(now):
        changed = true
    if changed:
        _changed()
    return {"seconds": elapsed, "stages": int(player.stage) - stages_before, "gold": int(player.gold) - gold_before}

func _refill_dungeon(now: int) -> bool:
    var previous := int(player.dungeon_tickets)
    var last := int(player.dungeon_last_refill)
    if last <= 0:
        player.dungeon_last_refill = now
        return false
    var gained := maxi(0, (now - last) / 600)
    if gained <= 0:
        return false
    player.dungeon_tickets = mini(3, previous + gained)
    player.dungeon_last_refill = last + gained * 600
    return int(player.dungeon_tickets) != previous

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

func attack_power() -> int:
    var power := 0
    for level in player.units:
        power += 4 + int(level) * 2
    for i in player.relics.size():
        power += 2 + int(player.relic_levels.get(str(i), 1))
    for key in player.equipment.keys():
        var item_index := int(player.equipment[key])
        if item_index >= 0 and item_index < player.inventory.size():
            var item: Dictionary = player.inventory[item_index]
            if item.get("kind", "") == "equipment":
                power += 2 * int(item.get("level", 1))
    var pet_index := int(player.active_pet)
    if pet_index >= 0 and pet_index < player.pets.size():
        power += 3 * int(player.pets[pet_index].get("level", 1))
    var ship_index := int(player.active_ship)
    if ship_index >= 0 and ship_index < player.ships.size():
        power += 4 * int(player.ships[ship_index].get("level", 1))
    power += maxi(0, int(player.guild.level) - 1) * 2
    if int(player.damage_until) > Time.get_unix_time_from_system():
        power = int(power * 1.5)
    return maxi(1, power)

func battle_step() -> int:
    var damage := _battle_step_internal()
    _changed()
    return damage

func _battle_step_internal() -> int:
    var damage := attack_power()
    player.enemy_hp = maxi(0, int(player.enemy_hp) - damage)
    if int(player.enemy_hp) <= 0:
        _clear_stage_internal()
    else:
        player.hero_hp = maxi(0, int(player.hero_hp) - maxi(1, int(player.stage) / 5))
        if int(player.hero_hp) <= 0:
            player.hero_hp = 100
            player.enemy_hp = 10 + int(player.stage) * 2
    return damage

func clear_stage() -> int:
    var reward := _clear_stage_internal()
    _changed()
    return reward

func _clear_stage_internal() -> int:
    var reward := reward_for_stage()
    player.gold += reward
    player.stage += 1
    player.total_kills += 10
    player.enemy_hp = 10 + int(player.stage) * 2
    player.hero_hp = mini(100, int(player.hero_hp) + 5)
    if int(player.stage) % 10 == 0:
        player.medals += 1
    if int(player.stage) % 5 == 0:
        player.gems += 10
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

func forge_equipment() -> bool:
    if int(player.gold) < 400:
        return false
    player.gold -= 400
    var item_id: int = player.inventory.size() + 1
    player.inventory.append({"kind": "equipment", "id": item_id, "level": 1})
    _changed()
    return true

func equip_item(unit_index: int, item_index: int) -> bool:
    if unit_index < 0 or unit_index >= player.units.size():
        return false
    if item_index < 0 or item_index >= player.inventory.size():
        return false
    if player.inventory[item_index].get("kind", "") != "equipment":
        return false
    player.equipment[str(unit_index)] = item_index
    _changed()
    return true

func upgrade_equipment(item_index: int) -> bool:
    if item_index < 0 or item_index >= player.inventory.size():
        return false
    var item: Dictionary = player.inventory[item_index]
    if item.get("kind", "") != "equipment":
        return false
    var cost := 150 * int(item.get("level", 1))
    if int(player.gold) < cost:
        return false
    player.gold -= cost
    item.level = int(item.get("level", 1)) + 1
    _changed()
    return true

func upgrade_relic(relic_index: int) -> bool:
    if relic_index < 0 or relic_index >= player.relics.size():
        return false
    var key := str(relic_index)
    var level := int(player.relic_levels.get(key, 1))
    if int(player.shards) < level * 5:
        return false
    player.shards -= level * 5
    player.relic_levels[key] = level + 1
    _changed()
    return true

func buy_pet() -> bool:
    if player.pets.size() >= 3 or int(player.gold) < 600:
        return false
    player.gold -= 600
    player.pets.append({"id": player.pets.size() + 1, "level": 1})
    if int(player.active_pet) < 0:
        player.active_pet = 0
    _changed()
    return true

func train_pet(index: int) -> bool:
    if index < 0 or index >= player.pets.size():
        return false
    var pet: Dictionary = player.pets[index]
    var cost := int(pet.get("level", 1)) * 250
    if int(player.gold) < cost:
        return false
    player.gold -= cost
    pet.level = int(pet.get("level", 1)) + 1
    _changed()
    return true

func select_pet(index: int) -> bool:
    if index < 0 or index >= player.pets.size():
        return false
    player.active_pet = index
    _changed()
    return true

func build_ship() -> bool:
    if int(player.stage) < 20 or player.ships.size() >= 2:
        return false
    if int(player.gold) < 1200 or int(player.shards) < 2:
        return false
    player.gold -= 1200
    player.shards -= 2
    player.ships.append({"id": player.ships.size() + 1, "level": 1})
    if int(player.active_ship) < 0:
        player.active_ship = 0
    _changed()
    return true

func upgrade_ship(index: int) -> bool:
    if index < 0 or index >= player.ships.size():
        return false
    var ship: Dictionary = player.ships[index]
    var cost := 500 * int(ship.get("level", 1))
    if int(player.gold) < cost:
        return false
    player.gold -= cost
    ship.level = int(ship.get("level", 1)) + 1
    _changed()
    return true

func explore_ship() -> bool:
    if int(player.active_ship) < 0 or int(player.ship_explore_next) > Time.get_unix_time_from_system():
        return false
    player.ship_explore_next = int(Time.get_unix_time_from_system()) + 600
    player.gold += 400 * int(player.ships[int(player.active_ship)].get("level", 1))
    player.shards += 1
    _changed()
    return true

func contribute_guild() -> bool:
    if int(player.gold) < 300:
        return false
    player.gold -= 300
    player.guild.xp += 1
    if int(player.guild.xp) >= int(player.guild.level) * 3:
        player.guild.xp = 0
        player.guild.level += 1
    _changed()
    return true

func run_guild_raid() -> bool:
    if int(player.stage) < 25 or int(player.guild.raid_next) > Time.get_unix_time_from_system():
        return false
    player.guild.raid_next = int(Time.get_unix_time_from_system()) + 300
    player.medals += 3 * int(player.guild.level)
    player.shards += 2
    _changed()
    return true

func run_dungeon() -> bool:
    _refill_dungeon(int(Time.get_unix_time_from_system()))
    if int(player.stage) < 10 or int(player.dungeon_tickets) <= 0:
        return false
    player.dungeon_tickets -= 1
    player.shards += 2 + int(player.stage) / 20
    player.gold += 300
    _changed()
    return true

func climb_tower() -> bool:
    var floor := int(player.tower_floor) + 1
    if int(player.stage) < floor * 5:
        return false
    player.tower_floor = floor
    player.gems += 5
    player.gold += floor * 100
    _changed()
    return true

func claim_achievement(kind: String) -> bool:
    if player.achievements.has(kind):
        return false
    var reached := false
    if kind == "stage10":
        reached = int(player.stage) >= 10
    elif kind == "kills100":
        reached = int(player.total_kills) >= 100
    elif kind == "tower5":
        reached = int(player.tower_floor) >= 5
    if not reached:
        return false
    player.achievements[kind] = true
    player.gems += 20
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
    player.enemy_hp = 12
    player.hero_hp = 100
    player.quest_end.clear()
    player.auto_battle = false
    _changed()
    return true
