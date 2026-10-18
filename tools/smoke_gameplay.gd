extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var game := preload("res://scripts/local_game_state.gd").new()
    game.persist_enabled = false
    root.add_child(game)
    game.set_process(false)
    game.player = game._default_player()
    assert(game.player.gold == 1000)
    assert(game.enhance_unit())
    assert(game.player.units[0] == 2 and game.player.gold == 800)
    assert(game.buy_unit())
    assert(game.player.units.size() == 2 and game.player.gold == 300)
    assert(game.start_quest(0))
    assert(not game.start_quest(0))
    game.player.quest_end["0"] = Time.get_unix_time_from_system() - 1
    game._process(0.1)
    assert(game.player.gold == 320 and game.player.quest_end.is_empty())
    assert(game.unlock_quest(1))
    assert(game.player.gold == 20)
    assert(not game.buy_relic())
    game.player.gold = 2000
    assert(game.buy_relic())
    assert(game.player.relics.size() == 1 and game.player.inventory.size() == 1)
    assert(game.buy_speed() and game.is_speed_active())
    game.player.gems = 200
    assert(game.buy_gem_buff("speed3"))
    assert(game.speed_multiplier() == 3.0)
    assert(game.buy_gem_buff("damage"))
    assert(game.player.gems == 0)
    game.player.stage = 5
    assert(game.play_local_pvp())
    assert(game.player.medals == 5)
    assert(not game.play_local_pvp())
    game.player.stage = 15
    assert(game.play_challenge(1))
    assert(not game.play_challenge(1))
    game.player.gold = 5000
    assert(game.forge_equipment())
    var equipment_index: int = game.player.inventory.size() - 1
    assert(game.equip_item(0, equipment_index))
    var power_before: int = game.attack_power()
    assert(game.upgrade_equipment(equipment_index))
    assert(game.attack_power() > power_before)
    game.player.shards = 10
    assert(game.upgrade_relic(0))
    assert(game.buy_pet())
    assert(game.train_pet(0))
    assert(game.select_pet(0))
    assert(game.run_dungeon())
    assert(game.player.dungeon_tickets == 2)
    assert(game.climb_tower())
    assert(game.player.tower_floor == 1)
    assert(game.claim_achievement("stage10"))
    assert(not game.claim_achievement("stage10"))
    game.player.stage = 25
    game.player.gold = 5000
    game.player.shards = 10
    assert(game.build_ship())
    assert(game.upgrade_ship(0))
    assert(game.explore_ship())
    assert(not game.explore_ship())
    assert(game.contribute_guild())
    assert(game.run_guild_raid())
    assert(not game.run_guild_raid())
    game.player.units[0] = 10
    game.player.shards = 20
    assert(game.promote_unit(0))
    assert(game.player.unit_grades[0] == 2)
    assert(not game.promote_unit(0))
    assert(game.claim_daily_login())
    assert(not game.claim_daily_login())
    game.player.daily_kills = 50
    assert(game.claim_daily_quest())
    assert(not game.claim_daily_quest())
    game.player.stage = 30
    assert(game.run_world_boss())
    assert(game.run_world_boss())
    assert(game.run_world_boss())
    assert(not game.run_world_boss())
    assert(not game.rebirth())
    game.player.stage = 50
    assert(game.rebirth())
    assert(game.player.stage == 1 and game.player.rebirths == 1)
    game.set_auto_battle(true)
    game.player.enemy_hp = 1
    game._process(1.0)
    assert(game.player.stage == 2 and game.player.enemy_hp > 0)
    game.player.last_seen_unix = int(Time.get_unix_time_from_system()) - 2
    game.player.enemy_hp = 1
    var offline: Dictionary = game.settle_offline()
    assert(offline.stages >= 1)
    game.player.auto_battle = false
    game.player.last_seen_unix = int(Time.get_unix_time_from_system()) - 86400
    assert(game.settle_offline().seconds == game.MAX_OFFLINE_SECONDS)
    game.player.dungeon_tickets = 0
    game.player.dungeon_last_refill = int(Time.get_unix_time_from_system()) - 1200
    assert(game._refill_dungeon(int(Time.get_unix_time_from_system())))
    assert(game.player.dungeon_tickets == 2)
    assert(not game.equip_item(0, 999))
    assert(not game.upgrade_relic(999))
    print("gameplay_smoke_pass")
    quit()
