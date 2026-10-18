# 화면별 사전 준비 (EF 5.5.5)

범위: 하단 메뉴 6개 진입 화면. 원본에는 이 외에도 팝업·상점 세부 화면·길드·펫 등 다수의 화면이 있다. 아래의 `기본 화면`은 현재 Godot에서 열리고 렌더되는 뼈대이지 원본과 동일한 완성 화면이 아니다.

| 하단 탭 | 원본 진입 클래스 | Godot 상태 | 우선 필요한 후속 작업 |
|---|---|---|---|
| 퀘스트 | `view/QuestView.as`, `subMenu/QuestSubMenu.as`, `itemRenderer/QuestItemRenderer.as` | 실기기 캡처 기준 행/아이콘 구성 | 글꼴·버튼·동적 전투 보정 |
| 병사 | `view/UnitView.as`, `subMenu/UnitSubMenu.as`, `itemRenderer/UnitItemRenderer.as` | 서브메뉴/목록 기본 화면 | 실제 보유 병사 데이터·원본 행/상세/구매 화면 |
| 유물 | `view/TreasureView.as`, `subMenu/TreasureSubMenu.as`, `itemRenderer/TreasureItemRenderer.as` | 빈 상태·서브메뉴 기본 화면 | 환생 잠금 조건·유물 목록/구매/초월/던전 |
| 대전 | `menu/BottomMenu.as`의 index 4 경로 | 진입 기본 화면 | 원본 대전 메뉴 경로·랭킹/상대 목록 실화면 캡처 |
| 인벤토리 | `inventory/InventoryMainView.as`, `inventory/subMenu/InventoryMainSubMenu.as` | 빈 상태·분류 기본 화면 | 원본 분류 탭, 7열 아이템 목록·상세 |
| 상점 | `view/ShopView.as`, `subMenu/ShopSubMenu.as`, `itemRenderer/ShopItemRender2.as` | 원본 AS3의 첫 3개 상품 제목 기반 기본 목록 | 실제 버튼/가격 배치·서버리스 구매 규칙 |

## 공통 구현 및 리소스

- `scripts/main_ui.gd`: 여섯 탭 선택, 공통 전투 영역/재화 바/하단 바, 기본 서브메뉴 및 목록. 서버 호출 없음.
- `assets/ui2_sheet.json`: UI2 시트 767프레임. 공통 버튼, 메뉴 아이콘, 상점 아이콘 포함.
- `assets/quest_sheet.json`: QUEST 시트 112프레임. 퀘스트 아이콘 포함.
- `assets/unit_item_sheet.json`: UNIT_ITEM 시트 477프레임. 병사 장비 화면 작업용.
- `assets/treasure_sheet.json`: TREASURE_SHEET 시트 580프레임. 유물 카드 작업용.
- `assets/treasure_ui_sheet.json`: TREASURE_UI 시트 45프레임. 유물 버튼/테두리 작업용.
- 시트 좌표는 `tools/read_amf_sheet.py`로 원본 SWF의 `.vo` 바이너리에서 복원했다.
- `tools/render_preview.gd` 실행 시 `reference/preview_{quest,unit,treasure,pvp,inventory,shop}.png`가 생성된다. 현재 비교 기준 원본 캡처는 퀘스트 화면 하나뿐이다. 나머지 다섯 화면은 실기기 원본 캡처를 확보해야 시각적 일치 검증이 가능하다.

## 구현 순서

1. 실기기에서 나머지 다섯 탭과 각 서브메뉴를 캡처한다. 원본에서 첫 환생 조건으로 잠긴 메뉴는 해당 상태를 함께 기록한다.
2. 화면마다 캡처를 640px 논리 좌표로 환산해 배경/행/아이콘/텍스트/버튼의 위치와 상태를 보정한다.
3. UNIT_ITEM·TREASURE 시트 프레임을 연결하고 동적 데이터/상세/팝업을 구현한다.
4. 서버 의존 동작은 동일 UI를 유지하되 로컬 데이터 흐름으로 대체한다.
