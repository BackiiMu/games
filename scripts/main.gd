extends Control

const MAP_TEXTURE := preload("res://assets/extracted/46_MAP_DEFAULT_jpg$4c9e9a736a4110cf4f487e389a1dbeae2043463872.png")

var status_label: Label
var stats_label: Label
var enhance_button: Button
var battle_panel: PanelContainer
var shop_panel: PanelContainer

func _ready() -> void:
    build_ui()
    refresh()

func build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("101827")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var map := TextureRect.new()
    map.texture = MAP_TEXTURE
    map.position = Vector2(0, 270)
    map.size = Vector2(640, 440)
    map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(map)

    var top := ColorRect.new()
    top.color = Color("172136e8")
    top.position = Vector2(0, 0)
    top.size = Vector2(640, 230)
    add_child(top)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var title := Label.new()
    title.text = "ENDLESS FRONTIER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    column.add_child(title)

    stats_label = Label.new()
    stats_label.add_theme_font_size_override("font_size", 18)
    column.add_child(stats_label)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.custom_minimum_size.y = 70
    column.add_child(status_label)

    var battle_button := Button.new()
    battle_button.text = "자동 전투"
    battle_button.custom_minimum_size.y = 56
    battle_button.pressed.connect(_on_battle)
    column.add_child(battle_button)

    enhance_button = Button.new()
    enhance_button.text = "유닛 강화"
    enhance_button.custom_minimum_size.y = 56
    enhance_button.pressed.connect(_on_enhance)
    column.add_child(enhance_button)

    var shop_button := Button.new()
    shop_button.text = "상점"
    shop_button.custom_minimum_size.y = 56
    shop_button.pressed.connect(_on_shop)
    column.add_child(shop_button)

    battle_panel = _make_panel("전투 화면\n\n적 유닛이 접근 중...\n전투 준비 완료")
    battle_panel.position = Vector2(24, 530)
    battle_panel.size = Vector2(592, 220)
    add_child(battle_panel)

    shop_panel = _make_panel("로컬 상점\n\n강화석 상자     300 골드\n전투 보급품     500 골드")
    shop_panel.position = battle_panel.position
    shop_panel.size = battle_panel.size
    shop_panel.visible = false
    add_child(shop_panel)

    for i in 5:
        var slot := PanelContainer.new()
        slot.position = Vector2(24 + i * 122, 900)
        slot.size = Vector2(110, 82)
        var slot_label := Label.new()
        slot_label.text = "UNIT %02d\nLv. %d" % [i + 1, LocalGameState.player.unit_level]
        slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        slot.add_child(slot_label)
        add_child(slot)

    var bottom := ColorRect.new()
    bottom.color = Color("101827f2")
    bottom.position = Vector2(0, 1000)
    bottom.size = Vector2(640, 136)
    add_child(bottom)

func refresh() -> void:
    var p: Dictionary = LocalGameState.player
    stats_label.text = "플레이어: %s\n스테이지: %d    골드: %d\n유닛 레벨: %d    처치: %d" % [p.nickname, p.stage, p.gold, p.unit_level, p.total_kills]
    var cost: int = 200 + (p.unit_level - 1) * 100
    enhance_button.text = "유닛 강화 (%d 골드)" % cost

func _on_battle() -> void:
    var reward := LocalGameState.clear_stage()
    status_label.text = "전투 승리! 스테이지 보상 %d 골드를 획득했습니다." % reward
    refresh()

func _on_enhance() -> void:
    if LocalGameState.enhance_unit():
        status_label.text = "유닛이 강화되었습니다."
    else:
        status_label.text = "골드가 부족합니다."
    refresh()

func _on_shop() -> void:
    shop_panel.visible = not shop_panel.visible
    battle_panel.visible = not shop_panel.visible
    status_label.text = "상점을 열었습니다." if shop_panel.visible else "전투 화면으로 돌아왔습니다."

func _make_panel(text: String) -> PanelContainer:
    var panel := PanelContainer.new()
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 20)
    panel.add_child(label)
    return panel
