"""Inventory decompiled view, submenu, and popup classes for reconstruction."""
import json
from pathlib import Path


project = Path(__file__).resolve().parents[1]
source = project.parent / "ef_decompiled" / "scripts" / "ekkorr" / "endlessfrontier"
patterns = {"view": "*View.as", "submenu": "*SubMenu.as", "popup": "*Popup.as"}
known = {
    "QuestView": "main",
    "UnitView": "main",
    "TreasureView": "main",
    "EventView": "main",
    "InventoryMainView": "main",
    "ShopView": "main",
    "QuestSubMenu": "main",
    "UnitSubMenu": "main",
    "TreasureSubMenu": "main",
    "EventSubMenu": "main",
    "InventoryMainSubMenu": "main",
    "ShopSubMenu": "main",
    "BuyUnitView": "shell",
    "BuyTreasureView": "shell",
    "ShopGemView": "shell",
    "PremiumShopView": "shell",
}
records = []
for kind, pattern in patterns.items():
    for path in source.rglob(pattern):
        records.append({
            "kind": kind,
            "class": path.stem,
            "source": str(path.relative_to(source)),
            "godot_status": known.get(path.stem, "not_started"),
        })
records.sort(key=lambda row: (row["kind"], row["source"]))
output = project / "assets" / "source_screen_index.json"
output.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"indexed={len(records)} output={output}")
