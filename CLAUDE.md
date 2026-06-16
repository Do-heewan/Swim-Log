# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> 프로젝트의 권위 있는 명세·절대 제약·데이터 모델은 `.claude/CLAUDE.md`(한국어)에 있다. **그 파일을 먼저 읽을 것.** 이 문서는 거기에 없는 "현재 코드 상태 / 명령어 / 아키텍처 큰 그림"만 보완한다. 두 문서가 충돌하면 `.claude/CLAUDE.md`의 제약이 우선한다.

## 현재 상태 (먼저 알 것)
이 저장소는 아직 **Flutter 기본 스타터** 단계다. `.claude/CLAUDE.md`가 묘사하는 구조(feature-first, Samsung Health 브릿지, Isar/Drift, Supabase, FastAPI)는 **목표일 뿐 아직 구현되지 않았다.**
- `lib/main.dart` — 기본 카운터 데모. `lib/` 하위에 feature 디렉터리 없음.
- `android/app/src/main/kotlin/com/noh/swim_log/MainActivity.kt` — 빈 `FlutterActivity`. **MethodChannel 브릿지 아직 없음.**
- `android/app/libs/` 디렉터리 없음 → Samsung Health AAR 미추가. ProGuard/R8 규칙 파일 없음.
- `pubspec.yaml` 의존성 = `flutter` / `cupertino_icons` / `flutter_lints`뿐. 저장소·상태관리·SDK 의존성 없음.
- git 저장소가 아님 (`git init` 미실행).

따라서 대부분의 작업은 "기존 코드 수정"이 아니라 "처음 만드는 것"이다. 코드를 찾다가 없으면 정상이다.

## 명령어
- 정적 분석(린트): `flutter analyze` — **변경 후 항상 통과 확인** (필수 규칙).
- 실행(실기기 전용): `flutter run -d <device-id>` — 에뮬레이터/데스크톱 미지원.
- 연결 기기 확인: `flutter devices`
- 전체 테스트: `flutter test`
- 단일 파일: `flutter test test/widget_test.dart`
- 테스트명으로 단일 실행: `flutter test --plain-name "<test name>"`
- 의존성 설치/갱신: `flutter pub get` · `flutter pub upgrade --major-versions`
- 네이티브 디버그 빌드: `cd android && ./gradlew assembleDebug` (Windows PowerShell: `.\gradlew.bat assembleDebug`)
- 네이티브 클린: `cd android && ./gradlew clean`

## 아키텍처: Dart ↔ Samsung Health 브릿지 (핵심 설계)
앱의 척추는 **MethodChannel 브릿지**다. Samsung Health Data SDK가 네이티브(Kotlin) 전용이라 다음 흐름을 따른다:
- Kotlin(`MainActivity` 또는 전용 plugin 클래스)이 SDK를 호출해 수영 세션을 읽고 → JSON 직렬화 가능한 `Map`으로 변환 → MethodChannel로 Dart에 전달.
- Dart 쪽이 그 `Map`을 `SwimmingLog` / `swimmingIntervals` 모델로 파싱한다 (모델 정의는 `.claude/CLAUDE.md`의 "데이터 모델" 참조).
- **읽기 전용**: SDK 쓰기 API 호출 금지.
- 구현 순서 규칙: **UI보다 브릿지 먼저**, 한 번에 한 마일스톤만.
- 브릿지 검증·디버깅 시 `swim-bridge-dump` 스킬로 실제 세션 1건을 raw JSON으로 덤프해 데이터 구조를 확인한다.

## 빌드 설정 메모 / 알려진 격차
- Java 17, `namespace`/`applicationId` = `com.noh.swim_log` 는 `android/app/build.gradle.kts`에 이미 설정됨.
- `minSdk`이 현재 `flutter.minSdkVersion`(Flutter 기본값)을 그대로 쓴다. 제약은 **minSdk 29**이므로 SDK 연동 시 명시적으로 `minSdk = 29` 이상으로 올릴 것.
- Samsung Health SDK 연동 시 필요한 작업: `samsung-health-data-api-*.aar`를 `android/app/libs/`에 두고 Gradle 의존성으로 추가 + R8/ProGuard에 SDK 클래스 strip 방지 keep 규칙 추가.
- Dart SDK 제약: `^3.11.5` (`pubspec.yaml`).
- 실행 환경: 갤럭시 실기기(S24+/Watch6), Samsung Health 6.30.2+ 필요.
