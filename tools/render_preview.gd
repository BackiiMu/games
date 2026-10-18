extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    change_scene_to_file("res://scenes/main.tscn")
    for frame in 5:
        await process_frame
    var titles := ["quest", "unit", "treasure", "pvp", "inventory", "shop"]
    for i in titles.size():
        current_scene.select_menu(i)
        for frame in 2:
            await process_frame
        var image := root.get_texture().get_image()
        var path := "res://reference/preview_%s.png" % titles[i]
        var result := image.save_png(path)
        print("preview_capture=", result, " path=", path, " size=", image.get_size())
    current_scene.select_menu(3)
    current_scene.open_subview(2)
    for frame in 2:
        await process_frame
    var detail := root.get_texture().get_image()
    print("preview_capture=", detail.save_png("res://reference/preview_tower.png"), " path=res://reference/preview_tower.png")
    quit()
