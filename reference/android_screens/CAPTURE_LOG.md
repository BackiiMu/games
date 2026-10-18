# 실기기 캡처 기록 (2026-10-19)

- 기기: Samsung SM-A826S, Android 화면 1080×2400 오버라이드
- 앱: `com.ekkorr.endlessfrontier` 5.5.5
- 방법: ADB `screencap -p` 및 `adb pull`; `tools/capture_android_reference.sh 이름`
- 상태: 튜토리얼 진행 중, 약 STAGE 37–50. 전투 배경과 숫자는 실시간으로 변한다.

## 파일별 내용

| 파일 | 실제 내용 |
| --- | --- |
| `initial.png` | 재접속 보상 팝업 |
| `quest_main.png` | 이벤트 배너 팝업(퀘스트 화면 위) |
| `quest_main_clean.png` | 퀘스트 기본 화면 |
| `soldier_main.png` | 병사 기본 화면 |
| `relic_main.png` | 유물 잠금 팝업: 첫 환생 이후 사용 가능 |
| `pvp_main.png` | 유물 잠금 팝업이 남아 있는 장면. 대전 화면 아님 |
| `inventory_main.png` | 같은 유물 잠금 팝업이 남아 있는 장면. 인벤토리 화면 아님 |
| `shop_main.png` | 같은 유물 잠금 팝업이 남아 있는 장면. 상점 화면 아님 |
| `pvp_locked.png` | 퀘스트 튜토리얼 손가락 안내 |
| `tutorial_after_quest_open.png` | 퀘스트 오픈 뒤 병사 화면 |
| `inventory_attempt.png` | 퀘스트 화면(메뉴 전환이 아직 지연된 상태) |
| `shop_attempt.png` | 버프 상점 기본 화면 |
| `inventory_clean.png` | 인벤토리 전체 분류, 빈 보관함 |
| `pvp_attempt.png` | 대전 잠금 팝업: 첫 환생 이후 입장 가능 |
| `relic_locked.png` | 대전 잠금 팝업이 남아 있는 장면. 유물 화면 아님 |

## 이어서 할 일

1. 대전 잠금 팝업은 중앙 확인 버튼(대략 x=540, y=1180)으로 닫는다.
2. 인벤토리 하위 분류(병사/펫/전함/유물), 상점 하위 메뉴, 병사 상세를 각각 캡처한다.
3. 첫 환생은 게임 진행 상태를 바꾸므로 화면 수집만을 위해 임의 실행하지 않는다. 유물/대전 내부는 그전까지 미수집으로 표시한다.
4. 자동 캡처 시 대상 앱 전면 여부를 스크립트가 확인한다. 현재 기기 연결 상태는 `adb devices`로 점검한다.
