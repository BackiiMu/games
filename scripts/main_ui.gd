extends Control

# Frame names and coordinates are decoded from EF.swf UI2.vo.
const UI := preload("res://assets/extracted/59_UI2_png$9aee312fb22e9d4533ea909f22f1c02b726976241.png")
const MAP := preload("res://assets/extracted/46_MAP_DEFAULT_jpg$4c9e9a736a4110cf4f487e389a1dbeae2043463872.png")
const TITLES := ["퀘스트", "병사", "유물", "대전", "인벤토리", "상점"]
const ICONS := ["menu_icon_01_on", "menu_icon_02_on", "menu_icon_04_on", "menu_icon_05_on", "TreasureBox", "menu_icon_06_on"]

var sheet: Dictionary
var content: Control
var bottom: Control
var stage_text: Label
var gold_text: Label
var notice: Label
var selected := 0

func _ready() -> void:
    sheet = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui2_sheet.json"))
    block(self, 0, 0, 640, 1136, Color("101010"))
    var map := TextureRect.new()
    map.texture = MAP
    map.position = Vector2.ZERO
    map.size = Vector2(640, 503)
    map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(map)
    map.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for i in 4:
        sprite(self, "UI_UNIT_ICONS%04d" % (i + 1), 35 + i * 97, 316, 70, 75)
    for i in 3:
        sprite(self, "UI_UNIT_ICONS%04d" % (i + 21), 350 + i * 86, 318, 67, 74)
    block(self, 0, 0, 640, 42, Color(0, 0, 0, 0.55))
    stage_text = label(self, "", 60, 3, 520, 39, 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
    for i in 3:
        sprite(self, ["UI_HUMAN_SKILL", "UI_ELF_SKILL", "UI_ORC_SKILL"][i], 12 + i * 45, 52, 38, 43)
    block(self, 0, 470, 640, 33, Color.BLACK)
    sprite(self, "UI_GEM_ICON", 250, 473, 27, 25)
    label(self, "0", 282, 471, 80, 30, 19, Color("ffda5c"))
    sprite(self, "UI_GOLD_ICON", 499, 471, 30, 30)
    gold_text = label(self, "", 534, 471, 102, 30, 19, Color("ffda5c"))
    content = Control.new()
    content.position = Vector2(0, 503)
    content.size = Vector2(640, 537)
    add_child(content)
    bottom = Control.new()
    bottom.position = Vector2(0, 1040)
    bottom.size = Vector2(640, 96)
    add_child(bottom)
    select_menu(0)
    refresh()

func select_menu(index: int) -> void:
    selected = index
    clear_layer(bottom)
    block(bottom, 0, 5, 640, 91, Color("171717"))
    for i in 6:
        var x := i * 640.0 / 6.0
        nine(bottom, "UI_MAIN_MENU_BG_ON" if i == selected else "UI_MAIN_MENU_BG_OFF", x, 9, 106, 87, 8)
        var icon := sprite(bottom, ICONS[i], x + 27, 11, 52, 51)
        icon.modulate.a = 1.0 if i == selected else 0.45
        label(bottom, TITLES[i], x, 65, 106, 28, 19, Color("ffe000") if i == selected else Color("aaaaaa"), HORIZONTAL_ALIGNMENT_CENTER)
        hit(bottom, x, 0, 106, 96, select_menu.bind(i))
    clear_layer(content)
    block(content, 0, 0, 640, 537, Color("101010"))
    if index == 0:
        build_quests()
    elif index == 1:
        build_units()
    else:
        block(content, 0, 0, 640, 88, Color("1f1f1f"))
        label(content, TITLES[index], 20, 17, 600, 50, 28, Color("ffdb65"))
        label(content, "원본 UI 분석 및 재현 진행 중", 20, 120, 600, 50, 21, Color("cccccc"))
        notice = null

func build_quests() -> void:
    block(content, 0, 0, 640, 88, Color("1f1f1f"))
    sprite(content, "BTN_SKILL_CHANGE2", 10, 24, 104, 40)
    game_button(content, "골드 획득", 145, 16, 210, 56, battle)
    game_button(content, "자동 전투", 405, 16, 210, 56, battle)
    for i in 4:
        var y := 88 + i * 110
        nine(content, "UI_LIST_BG", 0, y, 640, 110, 3)
        sprite(content, "UI_UNIT_ICONS%04d" % (i + 1), 16, y + 21, 63, 67)
        label(content, ["첫 번째 임무", "두 번째 임무", "세 번째 임무", "네 번째 임무"][i], 90, y + 9, 315, 32, 22, Color("ffda61"))
        sprite(content, "UI_GOLD_ICON", 95, y + 54, 24, 25)
        label(content, str((i + 1) * 125), 125, y + 52, 160, 30, 20, Color.WHITE)
        game_button(content, "실행", 475, y + 25, 148, 60, battle)
    notice = label(content, "", 15, 493, 610, 30, 18, Color("f4d771"))

func build_units() -> void:
    block(content, 0, 0, 640, 88, Color("1f1f1f"))
    label(content, "병사", 20, 17, 600, 50, 28, Color("ffdb65"))
    for i in 4:
        var y := 88 + i * 110
        nine(content, "UI_LIST_BG", 0, y, 640, 110, 3)
        sprite(content, "UI_UNIT_ICONS%04d" % (i + 1), 15, y + 17, 73, 76)
        label(content, "병사 %d" % (i + 1), 102, y + 15, 270, 31, 23, Color("ffdc65"))
        label(content, "Lv. %d" % LocalGameState.player.unit_level, 103, y + 53, 230, 30, 19, Color.WHITE)
        game_button(content, "강화", 475, y + 25, 148, 60, enhance)
    notice = label(content, "", 15, 493, 610, 30, 18, Color("f4d771"))

func battle() -> void:
    var reward: int = LocalGameState.clear_stage()
    notice.text = "승리! +%d 골드" % reward
    refresh()

func enhance() -> void:
    var success: bool = LocalGameState.enhance_unit()
    select_menu(1)
    notice.text = "강화 완료" if success else "골드 부족"
    refresh()

func refresh() -> void:
    stage_text.text = "STAGE %d" % LocalGameState.player.stage
    gold_text.text = str(LocalGameState.player.gold)

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

func sprite(parent: Control, name: String, x: float, y: float, w: float, h: float) -> TextureRect:
    var image := TextureRect.new()
    if sheet.has(name):
        image.texture = atlas_texture(name)
    image.position = Vector2(x, y)
    image.size = Vector2(w, h)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_SCALE
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
