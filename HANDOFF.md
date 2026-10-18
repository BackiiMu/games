# 작업 인수인계

## 현재 상태

- 대상: `com.ekkorr.endlessfrontier_5.5.5.xapk`
- 원본은 Godot이 아니라 Adobe AIR/Flash 앱이며 핵심 화면은 `EF.swf`에 있음.
- REA로 APK 구조와 패키지 정보를 확인했고, FFDec로 SWF XML 및 AS3 스크립트를 추출함.
- Godot 4 프로젝트 실행 확인 완료.
- 원본 배경 이미지와 추출 리소스를 Godot에 연결함.
- 로컬 저장, 스테이지 보상, 골드, 유닛 강화, 자동 전투, 상점 토글의 기본 동작 구현.

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

- `scripts/main.gd`: 현재 프로토타입 UI와 입력 처리
- `scripts/local_game_state.gd`: 서버리스 저장/게임 상태
- `assets/extracted/`: EF.swf에서 추출한 원본 이미지 리소스
- `reference/EF.swf`: 원본 SWF
- `reference/EF.xml`: SWF 리소스/심볼 분석 결과
- `../ef_decompiled/scripts/`: FFDec로 추출한 AS3 소스
- `REBUILD_RULES.md`: 작업 규칙

## 다음 작업

1. `TopMenu`, `BattleButton`, `ListBg`, `UnitIcon` 등 AS3 클래스와 SWF 심볼 좌표를 기준으로 메인 전투 화면을 절대 좌표 레이아웃으로 재구성.
2. `UI2`, `UNIT_ITEM`, `PET_SHEET`, `TREASURE_UI` 리소스를 실제 화면 요소에 연결.
3. 원본과 Godot 실행 화면을 같은 해상도로 비교하면서 상단 HUD, 전투 영역, 유닛 목록, 하단 메뉴를 순서대로 보정.
4. 이후 로컬 상점/보상/강화 흐름을 원본 화면 전환과 맞춘다.

현재 화면은 기능 검증용 프로토타입이며 최종 UI 재현은 아직 진행 중이다.
