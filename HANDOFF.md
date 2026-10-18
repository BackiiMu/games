# 작업 인수인계

## 현재 상태

- 대상: `com.ekkorr.endlessfrontier_5.5.5.xapk`
- 원본은 Godot이 아니라 Adobe AIR/Flash 앱이며 핵심 화면은 `EF.swf`에 있음.
- REA로 APK 구조와 패키지 정보를 확인했고, FFDec로 SWF XML 및 AS3 스크립트를 추출함.
- Godot 4 프로젝트 실행 확인 완료.
- 원본 배경 이미지와 추출 리소스를 Godot에 연결함.
- `UI2.vo`의 AMF3 좌표를 읽어 UI2 텍스처 시트의 프레임 767개를 `assets/ui2_sheet.json`으로 복원함.
- `scripts/main_ui.gd`가 현재 메인 씬. 원본 코드 기준 전투/콘텐츠/하단 메뉴의 640px 좌표계를 적용했고, 원본 프레임으로 하단 6개 메뉴, 퀘스트/병사 행, 재화 아이콘을 구성함.
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

- `scripts/main_ui.gd`: 현재 실행되는 UI와 입력 처리
- `scripts/main.gd`: 첫 프로토타입, 현재 씬에서는 사용하지 않음
- `assets/ui2_sheet.json`: SWF UI2 시트의 이름별 프레임 좌표
- `tools/read_amf_sheet.py`: `UI2.vo` AMF3 좌표 파서
- `scripts/local_game_state.gd`: 서버리스 저장/게임 상태
- `assets/extracted/`: EF.swf에서 추출한 원본 이미지 리소스
- `reference/EF.swf`: 원본 SWF
- `reference/EF.xml`: SWF 리소스/심볼 분석 결과
- `../ef_decompiled/scripts/`: FFDec로 추출한 AS3 소스
- `REBUILD_RULES.md`: 작업 규칙

## 다음 작업

1. 원본 앱 5.5.5의 실화면 캡처를 확보해 640px 기준 Godot 화면과 나란히 비교한다. 현재는 AS3의 배치 수치가 근거이며 실화면 비교는 미완료.
2. `QuestSubMenu`, `QuestItemRenderer`, `UnitView`, `TopMenu`의 세부 요소와 폰트/상태를 원본 화면에 맞게 보정한다.
3. `UNIT_ITEM`, `PET_SHEET`, `TREASURE_UI` 시트의 `.vo`도 같은 파서로 복원해 관련 화면에 적용한다.
4. 유물·대전·인벤토리·상점은 현재 화면 제목만 있는 자리 표시 상태. 각 화면을 원본 UI로 구현한다.
5. 이후 로컬 상점/보상/강화 흐름을 원본 화면 전환과 맞춘다.

현재 UI는 원본 리소스와 배치 코드를 반영한 중간 단계이며 최종 일치 검증은 아직 진행 중이다.
