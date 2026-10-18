extends Control

# Frame names and coordinates are decoded from EF.swf UI2.vo.
const UI := preload("res://assets/extracted/59_UI2_png$9aee312fb22e9d4533ea909f22f1c02b726976241.png")
const QUEST := preload("res://assets/extracted/76_QUEST_png.png")
const REFERENCE_BATTLE := preload("res://reference/endless_frontier_reference.png")
const TITLES := ["퀘스트", "병사", "유물", "대전", "인벤토리", "상점"]
const ICONS := ["menu_icon_01_on", "menu_icon_02_on", "menu_icon_04_on", "menu_icon_05_on", "TreasureBox", "menu_icon_06_on"]

var sheet: Dictionary
var quest_sheet: Dictionary
var screen: Control
var content: Control
var bottom: Control
var stage_text: Label
var gold_text: Label
var notice: Label
var selected := 0
var subview := -1
var feedback := ""

func _ready() -> void:
    sheet = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui2_sheet.json"))
    quest_sheet = JSON.parse_string(FileAccess.get_file_as_string("res://assets/quest_sheet.json"))
    block(self, 0, 0, 640, 1422, Color.BLACK)
    screen = Control.new()
    screen.position = Vector2(0, 50)
    screen.size = Vector2(640, 1380)
    add_child(screen)
    block(screen, 0, 0, 640, 1380, Color("101010"))
    var map := Sprite2D.new()
    var battle_crop := AtlasTexture.new()
    battle_crop.atlas = REFERENCE_BATTLE
    battle_crop.region = Rect2(0, 70, 1080, 793)
    map.texture = battle_crop
    map.position = Vector2.ZERO
    map.centered = false
    map.scale = Vector2(640.0 / 1080.0, 470.0 / 793.0)
    screen.add_child(map)
    # The captured battle is a visual reference until downloaded stage art is recovered.
    block(screen, 263, 3, 113, 32, Color("151515"))
    stage_text = label(screen, "", 263, 3, 113, 32, 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
    hit(screen, 80, 4, 55, 48, toggle_auto_battle)
    block(screen, 0, 470, 640, 33, Color.BLACK)
    sprite(screen, "UI_GEM_ICON", 250, 473, 27, 25)
    var gem_text := label(screen, "0", 282, 471, 80, 30, 19, Color("ffda5c"))
    gem_text.name = "GemText"
    sprite(screen, "UI_STAR_ICON", 376, 473, 21, 27)
    var medal_text := label(screen, "0", 404, 471, 88, 30, 19, Color("e54545"))
    medal_text.name = "MedalText"
    sprite(screen, "UI_GOLD_ICON", 499, 471, 30, 30)
    gold_text = label(screen, "", 534, 471, 102, 30, 19, Color("ffda5c"))
    content = Control.new()
    content.position = Vector2(0, 503)
    content.size = Vector2(640, 781)
    screen.add_child(content)
    bottom = Control.new()
    bottom.position = Vector2(0, 1284)
    bottom.size = Vector2(640, 96)
    screen.add_child(bottom)
    LocalGameState.state_changed.connect(_on_state_changed)
    select_menu(0)
    refresh()

func _on_state_changed() -> void:
    call_deferred("_redraw_from_state")

func _redraw_from_state() -> void:
    refresh()
    render_menu()

func select_menu(index: int) -> void:
    selected = index
    subview = -1
    feedback = ""
    render_menu()

func render_menu() -> void:
    clear_layer(bottom)
    block(bottom, 0, 5, 640, 91, Color("521b0a"))
    for i in 6:
        var x := i * 640.0 / 6.0
        nine(bottom, "UI_MAIN_MENU_BG_ON" if i == selected else "UI_MAIN_MENU_BG_OFF", x, 9, 106, 87, 8)
        var icon := sprite(bottom, ICONS[i], x + 27, 11, 52, 51)
        icon.modulate.a = 1.0 if i == selected else 0.45
        label(bottom, TITLES[i], x, 65, 106, 28, 19, Color("ffe000") if i == selected else Color("aa8e00"), HORIZONTAL_ALIGNMENT_CENTER)
        hit(bottom, x, 0, 106, 96, select_menu.bind(i))
    clear_layer(content)
    block(content, 0, 0, 640, 781, Color("101010"))
    if subview >= 0:
        build_subview()
    elif selected == 0:
        build_quests()
    elif selected == 1:
        build_units()
    elif selected == 2:
        build_treasures()
    elif selected == 3:
        build_pvp()
    elif selected == 4:
        build_inventory()
    elif selected == 5:
        build_shop()
    else:
        block(content, 0, 0, 640, 88, Color("1f1f1f"))
        label(content, TITLES[selected], 20, 17, 600, 50, 28, Color("ffdb65"))
        label(content, "원본 UI 분석 및 재현 진행 중", 20, 120, 600, 50, 21, Color("cccccc"))
        notice = null

func build_quests() -> void:
    block(content, 0, 0, 640, 88, Color("1e1e1e"))
    nine(content, "UI_COMMON_BUTTON_ON", 5, 5, 158, 77, 13)
    sprite(content, "BTN_SKILL_CHANGE2", 18, 22, 128, 49)
    hit(content, 5, 5, 158, 77, open_subview.bind(0))
    nine(content, "UI_COMMON_BUTTON_ON", 480, 5, 155, 77, 13)
    sprite(content, "UI_MOVIE_SMALL", 511, 23, 38, 42)
    sprite(content, "UI_GOLD_ICON", 547, 29, 23, 24)
    label(content, "6a", 574, 26, 52, 34, 21, Color("ffd04b"))
    hit(content, 480, 5, 155, 77, open_subview.bind(1))
    for i in 7:
        var y := 88 + i * 110
        nine(content, "UI_LIST_BG", 0, y, 640, 110, 3)
        var icon := quest_sprite(content, "M_%02d_on" % (i + 1), 17, y + 15, 80, 80)
        var locked := int(LocalGameState.player.quest_levels[i]) <= 0
        if locked:
            icon.modulate = Color(0.34, 0.34, 0.34)
        label(content, "%d. %s" % [i + 1, ["기사단 청소", "기사단 무기 손질", "기사단 장비 손질", "차원의 틈새 감시", "만만한 차원수 처치", "사나운 차원수 처치", "수정 원석 채굴"][i]], 108, y + 8, 365, 34, 23,
            Color("d9d9d9") if not locked else Color("777777"))
        sprite(content, "UI_GOLD_ICON" if not locked else "UI_GRAY_GOLD", 113, y + 62, 24, 24)
        label(content, ["20", "156", "2.7a", "43.6a", "1.1b", "23.5b", "500b"][i], 143, y + 60, 170, 28, 19,
            Color("ffca44") if not locked else Color("888888"))
        if i == 0:
            block(content, 244, y + 62, 178, 22, Color("5c481a"))
        var remaining := LocalGameState.quest_remaining(i)
        label(content, "%02d:%02d" % [remaining / 60, remaining % 60] if remaining > 0 else ["00:01", "00:03", "00:05", "00:10", "00:30", "01:00", "02:00"][i], 368, y + 60, 67, 27, 18, Color("b9b9b9"))
        nine(content, "UI_COMMON_BUTTON_ON" if not locked else "UI_COMMON_BUTTON_OFF", 472, y + 11, 160, 83, 13)
        label(content, "+7" if i == 0 else "", 481, y + 12, 126, 31, 21, Color.WHITE)
        sprite(content, "UI_GOLD_ICON" if not locked else "UI_GRAY_GOLD", 490, y + 59, 26, 26)
        label(content, ["1", "110", "1.6a", "25.1a", "401.8a", "6.8b", "100b"][i], 520, y + 57, 102, 29, 20,
            Color("ffd058") if not locked else Color("777777"))
        hit(content, 472, y + 11, 160, 83, quest_action.bind(i))
    notice = label(content, feedback, 15, 745, 610, 30, 18, Color("f4d771"))

func build_units() -> void:
    menu_bar("병사", ["BTN_BUY_UNIT_SHOP", "BTN_TIME_SHOP", "BTN_ALL_LEVELUP", "UNIT_MENU_4"],
        ["병사구입", "시간의 상점", "일괄 강화", "병사 장비"])
    for i in LocalGameState.player.units.size():
        var y: int = 88 + i * 110
        nine(content, "UI_LIST_BG", 0, y, 640, 110, 3)
        sprite(content, "UI_UNIT_ICONS%04d" % (i + 1), 15, y + 17, 73, 76)
        label(content, "병사 %d" % (i + 1), 102, y + 15, 270, 31, 23, Color("ffdc65"))
        label(content, "Lv. %d" % LocalGameState.player.units[i], 103, y + 53, 230, 30, 19, Color.WHITE)
        game_button(content, "강화 %d" % LocalGameState.unit_cost(i), 475, y + 25, 148, 60, enhance_unit.bind(i))
        hit(content, 15, y + 12, 440, 85, open_subview.bind(4))
    notice = label(content, feedback, 15, 493, 610, 30, 18, Color("f4d771"))

func build_treasures() -> void:
    menu_bar("유물 %d/20" % LocalGameState.player.relics.size(), ["TREASURE_SHOP", "BTN_TIME_SHOP", "BTN_TRANS_TREASURE1", "DUNGEON_ITEM0001"],
        ["유물구입", "시간의 상점", "유물 초월", "던전"])
    if LocalGameState.player.relics.is_empty():
        label(content, "소유한 유물이 없습니다", 70, 220, 500, 60, 23, Color("999999"), HORIZONTAL_ALIGNMENT_CENTER)
    else:
        for i in mini(LocalGameState.player.relics.size(), 5):
            panel_row(85 + i * 112, "유물 %d" % LocalGameState.player.relics[i], "보유 중", "TreasureBox")
    notice = null

func build_pvp() -> void:
    menu_bar("명예코인 : %d" % LocalGameState.player.medals, ["BTN_COIN_SHOP"], ["명예 상점"])
    var titles := ["무한랭킹전", "일일 랭킹전", "도전의 탑", "차원의 전투", "월드 보스"]
    var icons := ["UI_PVP_ICON", "UI_DAILY_RANKING_ICON_ON", "ICON_TOWER", "UI_OUTLAND_ICON", "BOSS-RAID-ICON"]
    for i in titles.size():
        var y := 80 + i * 127
        panel_row(y, titles[i], "입장 및 보상 확인", icons[i])
        hit(content, 0, y, 640, 106, open_subview.bind(i))
    notice = null

func build_inventory() -> void:
    menu_bar("인벤토리", ["UNIT_MENU_1", "TreasureBox", "UI-PET-TICKET", "BATTLE_SHIP_ICON"],
        ["병사", "유물", "펫", "전함"])
    if LocalGameState.player.inventory.is_empty():
        label(content, "보관된 내역이 없습니다.", 50, 215, 540, 60, 22, Color("999999"), HORIZONTAL_ALIGNMENT_CENTER)
    else:
        for i in mini(LocalGameState.player.inventory.size(), 5):
            panel_row(85 + i * 112, "유물 %d" % LocalGameState.player.inventory[i].id, "보관 중", "TreasureBox")
    notice = null

func build_shop() -> void:
    menu_bar("상점", ["BTN_GEM_SHOP", "BTN_GOLD_SHOP", "BTN_BUFF_SHOP", "BTN_BUY_UNIT_SHOP"],
        ["보석 상점", "버프 상점", "프리미엄", "병사 상점"])
    panel_row(90, "20분간 게임속도 2배", "로컬 골드 500", "UI_SHOP_SPEED2")
    hit(content, 0, 90, 640, 106, buy_speed)
    panel_row(202, "20분간 게임속도 3배", "보석 100", "UI_SHOP_SPEED3")
    hit(content, 0, 202, 640, 106, buy_gem_buff.bind("speed3"))
    panel_row(314, "20분간 병사공격력 증가", "보석 100", "UI_SHOP_STRONG_UP")
    hit(content, 0, 314, 640, 106, buy_gem_buff.bind("damage"))
    label(content, feedback, 20, 440, 600, 35, 18, Color("f4d771"))
    notice = null

func open_subview(index: int) -> void:
    subview = index
    render_menu()

func close_subview() -> void:
    subview = -1
    render_menu()

func build_subview() -> void:
    var title := ""
    var icon := "TreasureBox"
    var rows: Array[String] = []
    match selected:
        0:
            title = ["퀘스트 스킬", "퀘스트 보상"][mini(subview, 1)]
            icon = "BTN_SKILL_CHANGE2" if subview == 0 else "UI_MOVIE_SMALL"
            rows = ["공격력 %d" % LocalGameState.attack_power(),
                "적 체력 %d / 아군 체력 %d" % [LocalGameState.player.enemy_hp, LocalGameState.player.hero_hp],
                "자동 전투: 켜짐" if LocalGameState.player.auto_battle else "자동 전투: 꺼짐"]
        1:
            title = ["병사구입", "시간의 상점", "일괄 강화", "병사 장비", "병사 상세"][mini(subview, 4)]
            icon = ["BTN_BUY_UNIT_SHOP", "BTN_TIME_SHOP", "BTN_ALL_LEVELUP", "UNIT_MENU_4", "UNIT_MENU_1"][mini(subview, 4)]
            rows = ["보유 병사와 슬롯", "강화 및 장비", "로컬 데이터로 확장 예정"]
        2:
            title = ["유물구입", "시간의 상점", "유물 초월", "던전"][mini(subview, 3)]
            icon = ["TREASURE_SHOP", "BTN_TIME_SHOP", "BTN_TRANS_TREASURE1", "DUNGEON_ITEM0001"][mini(subview, 3)]
            rows = ["유물 슬롯", "유물 조각 및 재화", "첫 환생 이후 원본에서 해금"]
        3:
            title = ["무한랭킹전", "일일 랭킹전", "도전의 탑", "차원의 전투", "월드 보스", "명예 상점"][mini(subview, 5)]
            icon = ["UI_PVP_ICON", "UI_DAILY_RANKING_ICON_ON", "ICON_TOWER", "UI_OUTLAND_ICON", "BOSS-RAID-ICON", "BTN_COIN_SHOP"][mini(subview, 5)]
            rows = ["도전 정보", "보상 목록", "온라인 상대 데이터는 로컬 모드에 포함되지 않습니다"]
        4:
            title = ["병사", "유물", "펫", "전함"][mini(subview, 3)] + " 인벤토리"
            icon = ["UNIT_MENU_1", "TreasureBox", "UI-PET-TICKET", "BATTLE_SHIP_ICON"][mini(subview, 3)]
            rows = ["보관된 내역이 없습니다."]
        5:
            title = ["보석 상점", "버프 상점", "프리미엄 상점", "병사 상점"][mini(subview, 3)]
            icon = ["BTN_GEM_SHOP", "BTN_GOLD_SHOP", "BTN_BUFF_SHOP", "BTN_BUY_UNIT_SHOP"][mini(subview, 3)]
            rows = ["상품 목록", "로컬 재화 규칙 준비 중", "온라인 결제는 구현하지 않습니다"]
    block(content, 0, 0, 640, 76, Color("1f2020"))
    sprite(content, "UI_ARROW_HEAD", 14, 19, 36, 36)
    label(content, title, 63, 8, 550, 59, 25, Color("ffdc65"))
    hit(content, 0, 0, 65, 76, close_subview)
    sprite(content, icon, 252, 109, 136, 136)
    for i in rows.size():
        panel_row(284 + i * 110, rows[i], "", icon)
    if selected == 0 and subview == 0:
        game_button(content, "자동 전투 끄기" if LocalGameState.player.auto_battle else "자동 전투 켜기", 200, 660, 240, 65, local_action)
    elif selected == 1 and subview == 0:
        game_button(content, "병사 구매", 200, 660, 240, 65, local_action)
    elif selected == 1 and subview == 2:
        game_button(content, "일괄 강화", 200, 660, 240, 65, local_action)
    elif selected == 2 and subview == 0:
        game_button(content, "유물 구매 (%d)" % LocalGameState.RELIC_COST, 200, 660, 240, 65, local_action)
    elif selected == 3 and subview < 5:
        game_button(content, "로컬 도전", 200, 660, 240, 65, local_action)
    elif selected == 5 and subview == 1:
        game_button(content, "속도 버프 구매", 200, 660, 240, 65, local_action)
    label(content, feedback, 40, 735, 560, 35, 18, Color("f4d771"), HORIZONTAL_ALIGNMENT_CENTER)
    notice = null

func menu_bar(title: String, icons: Array, captions: Array) -> void:
    block(content, 0, 0, 640, 76, Color("1f2020"))
    label(content, title, 12, 4, 190, 67, 21, Color("ffdc65"))
    var button_width := 102.0
    var first_x := 640.0 - icons.size() * (button_width + 3.0) - 4.0
    for i in icons.size():
        var x: float = first_x + i * (button_width + 3.0)
        nine(content, "UI_COMMON_BUTTON_ON", x, 7, button_width, 62, 12)
        sprite(content, icons[i], x + 5, 12, 35, 35)
        label(content, captions[i], x + 2, 42, button_width - 4, 24, 13, Color("f2cf6d"), HORIZONTAL_ALIGNMENT_CENTER)
        hit(content, x, 7, button_width, 62, open_subview.bind(5 if selected == 3 else i))

func panel_row(y: float, title: String, subtitle: String, icon_name: String) -> void:
    nine(content, "UI_LIST_BG", 0, y, 640, 106, 3)
    sprite(content, icon_name, 15, y + 15, 76, 76)
    label(content, title, 105, y + 10, 510, 39, 21, Color("dddddd"))
    label(content, subtitle, 105, y + 51, 510, 35, 16, Color("999999"))

func battle() -> void:
    var reward: int = LocalGameState.clear_stage()
    feedback = "승리! +%d 골드" % reward
    refresh()

func enhance_unit(index: int) -> void:
    var success: bool = LocalGameState.enhance_unit(index)
    feedback = "강화 완료" if success else "골드 부족"
    render_menu()
    refresh()

func quest_action(index: int) -> void:
    if int(LocalGameState.player.quest_levels[index]) <= 0:
        feedback = "퀘스트 해금" if LocalGameState.unlock_quest(index) else "골드 부족"
    else:
        feedback = "퀘스트 시작" if LocalGameState.start_quest(index) else "진행 중"
    render_menu()

func toggle_auto_battle() -> void:
    LocalGameState.set_auto_battle(not LocalGameState.player.auto_battle)
    refresh()

func buy_speed() -> void:
    feedback = "2배 속도 적용" if LocalGameState.buy_speed() else "골드 부족"
    render_menu()

func buy_gem_buff(kind: String) -> void:
    feedback = "버프 적용" if LocalGameState.buy_gem_buff(kind) else "보석 부족"
    render_menu()

func local_action() -> void:
    var success := false
    if selected == 0 and subview == 0:
        LocalGameState.set_auto_battle(not LocalGameState.player.auto_battle)
        success = true
    elif selected == 1 and subview == 0:
        success = LocalGameState.buy_unit()
    elif selected == 1 and subview == 2:
        for i in LocalGameState.player.units.size():
            success = LocalGameState.enhance_unit(i) or success
    elif selected == 2 and subview == 0:
        success = LocalGameState.buy_relic()
    elif selected == 3 and subview < 5:
        success = LocalGameState.play_challenge(subview)
    elif selected == 5 and subview == 1:
        success = LocalGameState.buy_speed()
    feedback = "완료" if success else "조건 또는 재화 부족"
    render_menu()

func refresh() -> void:
    stage_text.text = "STAGE %d" % LocalGameState.player.stage
    gold_text.text = str(LocalGameState.player.gold)
    screen.get_node("GemText").text = str(LocalGameState.player.gems)
    screen.get_node("MedalText").text = str(LocalGameState.player.medals)

func clear_layer(parent: Control) -> void:
    for child in parent.get_children():
        parent.remove_child(child)
        child.queue_free()

func atlas_texture(name: String) -> AtlasTexture:
    var entry: Array = sheet[name]
    var texture := AtlasTexture.new()
    texture.atlas = UI
    texture.region = Rect2(entry[0], entry[1], entry[2], entry[3])
    return texture

func quest_sprite(parent: Control, name: String, x: float, y: float, w: float, h: float) -> Sprite2D:
    var image := Sprite2D.new()
    if quest_sheet.has(name):
        var entry: Array = quest_sheet[name]
        var texture := AtlasTexture.new()
        texture.atlas = QUEST
        texture.region = Rect2(entry[0], entry[1], entry[2], entry[3])
        image.texture = texture
        image.scale = Vector2(w / float(entry[2]), h / float(entry[3]))
    image.centered = false
    image.position = Vector2(x, y)
    parent.add_child(image)
    return image

func sprite(parent: Control, name: String, x: float, y: float, w: float, h: float) -> Sprite2D:
    var image := Sprite2D.new()
    if sheet.has(name):
        image.texture = atlas_texture(name)
        var entry: Array = sheet[name]
        image.scale = Vector2(w / float(entry[2]), h / float(entry[3]))
    image.centered = false
    image.position = Vector2(x, y)
    parent.add_child(image)
    return image

func nine(parent: Control, name: String, x: float, y: float, w: float, h: float, margin: int) -> void:
    var image := NinePatchRect.new()
    image.texture = atlas_texture(name)
    image.position = Vector2(x, y)
    image.size = Vector2(w, h)
    image.patch_margin_left = margin
    image.patch_margin_right = margin
    image.patch_margin_top = margin
    image.patch_margin_bottom = margin
    if name == "UI_LIST_BG":
        image.modulate = Color(0.64, 0.64, 0.64)
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(image)

func block(parent: Control, x: float, y: float, w: float, h: float, color: Color) -> void:
    var rectangle := ColorRect.new()
    rectangle.position = Vector2(x, y)
    rectangle.size = Vector2(w, h)
    rectangle.color = color
    rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(rectangle)

func label(parent: Control, value: String, x: float, y: float, w: float, h: float, font_size: int, color: Color,
        alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var text := Label.new()
    text.text = value
    text.position = Vector2(x, y)
    text.size = Vector2(w, h)
    text.horizontal_alignment = alignment
    text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    text.add_theme_font_size_override("font_size", font_size)
    text.add_theme_color_override("font_color", color)
    text.add_theme_color_override("font_shadow_color", Color.BLACK)
    text.add_theme_color_override("font_outline_color", Color.BLACK)
    text.add_theme_constant_override("outline_size", 2)
    text.add_theme_constant_override("shadow_offset_x", 1)
    text.add_theme_constant_override("shadow_offset_y", 2)
    text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(text)
    return text

func hit(parent: Control, x: float, y: float, w: float, h: float, callback: Callable) -> void:
    var button := Button.new()
    button.flat = true
    button.position = Vector2(x, y)
    button.size = Vector2(w, h)
    button.pressed.connect(callback)
    parent.add_child(button)

func game_button(parent: Control, value: String, x: float, y: float, w: float, h: float, callback: Callable) -> void:
    nine(parent, "UI_COMMON_BUTTON_ON", x, y, w, h, 18)
    label(parent, value, x, y, w, h, 22, Color("f7e8c9"), HORIZONTAL_ALIGNMENT_CENTER)
    hit(parent, x, y, w, h, callback)
