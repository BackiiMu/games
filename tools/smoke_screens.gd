extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    change_scene_to_file("res://scenes/main.tscn")
    for frame in 4:
        await process_frame
    var counts := [2, 5, 4, 6, 4, 4]
    var visited := 0
    for tab in counts.size():
        current_scene.select_menu(tab)
        await process_frame
        visited += 1
        for sub in counts[tab]:
            current_scene.open_subview(sub)
            await process_frame
            visited += 1
            current_scene.close_subview()
            await process_frame
    print("screen_smoke_pass visited=", visited)
    quit()
