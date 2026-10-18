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
    quit()
