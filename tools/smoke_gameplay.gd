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
    assert(not game.rebirth())
    game.player.stage = 50
    assert(game.rebirth())
    assert(game.player.stage == 1 and game.player.rebirths == 1)
    game.set_auto_battle(true)
    game.player.enemy_hp = 1
    game._process(1.0)
    assert(game.player.stage == 2 and game.player.enemy_hp > 0)
    print("gameplay_smoke_pass")
    quit()
