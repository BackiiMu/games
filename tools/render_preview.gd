extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    change_scene_to_file("res://scenes/main.tscn")
    for frame in 5:
        await process_frame
    var image := root.get_texture().get_image()
    var result := image.save_png("res://reference/godot_current.png")
    print("preview_capture=", result, " size=", image.get_size())
    quit()
