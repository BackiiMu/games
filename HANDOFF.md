# 작업 인수인계

## 현재 상태

- 대상: `com.ekkorr.endlessfrontier_5.5.5.xapk`
- 원본은 Godot이 아니라 Adobe AIR/Flash 앱이며 핵심 화면은 `EF.swf`에 있음.
- REA로 APK 구조와 패키지 정보를 확인했고, FFDec로 SWF XML 및 AS3 스크립트를 추출함.
- Godot 4 프로젝트 실행 확인 완료.
- 원본 배경 이미지와 추출 리소스를 Godot에 연결함.
- `UI2.vo`의 AMF3 좌표를 읽어 UI2 텍스처 시트의 프레임 767개를 `assets/ui2_sheet.json`으로 복원함.
- `scripts/main_ui.gd`가 현재 메인 씬. 원본 코드 기준 전투/콘텐츠/하단 메뉴의 640px 좌표계를 적용했고, 원본 프레임으로 하단 6개 메뉴, 퀘스트/병사 행, 재화 아이콘을 구성함.
- 2026-10-19 원본 실기기 캡처를 기준으로 뷰포트를 640×1422로 맞추고 상단 50px 검은 여백, 470px 전투 영역, 33px 재화 바, 88px 퀘스트 서브메뉴, 110px 간격의 7개 퀘스트 행, 6개 하단 메뉴를 실렌더로 확인함. `QUEST.vo`의 좌표를 복원한 `assets/quest_sheet.json`으로 원본 퀘스트 아이콘을 사용함.
- Godot 실렌더 `reference/godot_current.png`는 `tools/render_preview.gd`로 생성. 원본 캡처 `reference/endless_frontier_reference.png`와 비교할 것. 현재 전투 영역은 원본 캡처의 정적 크롭이므로 실제 전투 재현은 아님. 글꼴/버튼 스타일 및 퀘스트 외 메뉴도 아직 차이가 큼.
- 로컬 저장, 스테이지 보상, 골드, 유닛 강화, 자동 전투의 기본 동작 구현. 하단 6개 탭은 모두 기본 화면으로 진입 가능하며, 퀘스트 외 화면은 원본 실화면 대조 전 단계임.

## 원본 APK 실행 조사 (2026-10-19)

- 원본 XAPK: `../com.ekkorr.endlessfrontier_5.5.5.xapk`. 기본 APK와 언어/화면 밀도/ABI 분할 APK가 들어 있으며 OBB는 없음.
- 기본 APK는 `reference/main.apk`에 보관되어 있음. 실행할 때는 기본 APK만이 아니라 필요한 분할 APK를 함께 설치해야 함.
- XAPK에 포함된 네이티브 ABI 분할은 `config.armeabi_v7a.apk`(32비트 ARM) 하나임. 설치된 AVD는 `Medium_Phone_API_36`, ARM64 시스템 이미지. 32비트 앱 지원 여부는 부팅 후 미확인.
- `adb`와 Android Emulator는 `~/Library/Android/sdk`에 설치되어 있으나, AVD 부팅은 `Not enough space to create userdata partition`으로 실패함. 당시 AVD 경로의 여유 공간 약 5.9GB, 요구량 약 7.4GB. `-partition-size 2048` 옵션으로 재시도해도 같은 검사에서 실패함.
- 당시 `adb devices -l`에 연결 기기는 없었음. 따라서 원본 앱 실행 화면은 아직 확보하지 못함.
- 다음 시도: 32비트 ARM 앱을 지원하는 Android 실기기 연결 후 `adb install-multiple`로 기본 APK, `config.armeabi_v7a.apk`, `config.ko.apk`, `config.xhdpi.apk` 등을 함께 설치. 또는 디스크 공간을 확보하고 32비트 지원 시스템 이미지로 별도 AVD를 준비. 기존 AVD 데이터는 임의로 삭제하지 말 것.

### 실기기 실행 결과

- 이후 Android 14, `arm64-v8a,armeabi-v7a,armeabi` 지원 실기기를 연결해 `adb install-multiple`로 기본 APK와 ARMv7/한국어/xhdpi 분할 APK를 함께 설치했고 성공함.
- 원본 `AIRAppEntry` 실행 후 로딩, 튜토리얼, 메인 퀘스트 UI까지 확인함. `SKIP`으로 튜토리얼 대화를 넘겨 기준 화면을 확보함.
- 비교용 캡처: `reference/endless_frontier_reference.png` (1080×2400). 상단 전투 화면, 검은 33px 재화 바, 퀘스트 서브메뉴, 다수의 110px 목록 행, 하단 6개 메뉴가 실제로 표시됨.
- Android가 간헐적으로 “응답하지 않음”을 표시했지만 `대기` 후 게임 상태와 스테이지가 진행됐음. 원인 미확인. 캡처 시점에는 대화상자가 사라진 상태임.
- 실화면을 Godot 실렌더와 비교해 메인 퀘스트 화면 구조와 아이콘을 보정함. 정적 전투 크롭과 버튼/글꼴의 차이는 아직 남음.

## 우선순위 규칙

1. 원본과 구별하기 어려운 UI/그래픽 재현이 최우선.
2. 원본 화면의 좌표, 크기, 레이어, 폰트, 이미지, 버튼 상태를 화면별로 맞춘다.
3. UI 재현 후 서버 없이 동작하는 로컬 게임 로직을 확장한다.

## 실행

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor
```

프로젝트 경로는 이 문서가 있는 `godot_rebuild` 디렉터리다.

## 주요 경로

- `scripts/main_ui.gd`: 현재 실행되는 UI와 입력 처리
- `scripts/main.gd`: 첫 프로토타입, 현재 씬에서는 사용하지 않음
- `assets/ui2_sheet.json`: SWF UI2 시트의 이름별 프레임 좌표
- `assets/quest_sheet.json`: SWF QUEST 시트의 이름별 프레임 좌표
- `tools/read_amf_sheet.py`: `UI2.vo` AMF3 좌표 파서
- `tools/render_preview.gd`: Godot 메인 씬 실렌더 캡처 (`reference/godot_current.png`)
- `scripts/local_game_state.gd`: 서버리스 저장/게임 상태
- `assets/extracted/`: EF.swf에서 추출한 원본 이미지 리소스
- `reference/EF.swf`: 원본 SWF
- `reference/EF.xml`: SWF 리소스/심볼 분석 결과
- `../ef_decompiled/scripts/`: FFDec로 추출한 AS3 소스
- `REBUILD_RULES.md`: 작업 규칙
- `SCREEN_PREP.md`: 하단 6개 화면의 원본 클래스, 현재 범위, 리소스 및 후속 작업
- `assets/source_screen_index.json`: 디컴파일된 View/SubMenu/Popup 클래스 288개 목록과 Godot 진행 상태
- `GAMEPLAY_STATUS.md`: 서버리스 로컬 게임 루프와 미구현 기능의 정확한 범위

## 다음 작업

1. `reference/endless_frontier_reference.png`와 `reference/godot_current.png`를 나란히 비교하며 `QuestSubMenu`, `QuestItemRenderer`, `UnitView`, `TopMenu`의 폰트/버튼/상태를 더 보정한다.
2. 정적 전투 크롭을 원본 시트의 배경·유닛·효과 레이어로 대체해 스테이지 UI와 로컬 게임 상태가 시각적으로 일치하게 한다.
3. `UNIT_ITEM`, `PET_SHEET`, `TREASURE_UI` 시트의 `.vo`도 같은 파서로 복원해 관련 화면에 적용한다.
4. 유물·대전·인벤토리·상점의 기본 뼈대를 원본 실기기 캡처와 비교해 원본 UI로 정밀화한다.
5. 이후 로컬 상점/보상/강화 흐름을 원본 화면 전환과 맞춘다.

현재 UI는 원본 리소스와 실기기 캡처를 반영한 중간 단계이며 최종 일치 검증은 아직 진행 중이다.
