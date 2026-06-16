# 수영 기록 분석 앱 (개인 프로젝트)

## 목적
갤럭시 워치 수영 기록을 Samsung Health에서 읽어와 시각화하고, 다음 운동 목표를
세우도록 돕는 개인용 앱. 배포/출시 계획 없음 — 개발자 모드(읽기 전용)로만 동작.

## 스택
- 앱: Flutter (Dart), feature-first 구조
- 데이터: Samsung Health Data SDK ← 네이티브 MethodChannel (Kotlin) 브릿지
- 저장: 로컬 우선 (Isar 또는 Drift). 동기화 필요 시 Supabase(Postgres)
- (이후) AI 코칭: FastAPI

## 절대 제약 (YOU MUST)
- 실기기에서만 동작. 에뮬레이터 미지원 → 빌드/실행은 연결된 갤럭시 기기(S24+/Watch6) 기준.
- Samsung Health 6.30.2+ 필요. Java 17, Android minSdk 29.
- SDK는 `samsung-health-data-api-*.aar`를 `android/app/libs/`에 두고 Gradle 의존성으로 추가.
  ProGuard/R8에서 SDK 클래스를 strip하지 않도록 keep 규칙 필수.
- 읽기 전용. Samsung Health에 데이터를 쓰지 말 것.

## 데이터 모델 (브릿지가 반환할 형태)
- 운동 타입: POOL_SWIMMING / OPEN_WATER_SWIMMING
- SwimmingLog: poolLength, poolLengthUnit, totalDistance, totalDuration, swimmingIntervals[]
- StrokeType: BUTTERFLY / BACKSTROKE / FREESTYLE / BREASTSTROKE / KICK_BOARD / MIXED
- 목표 지표: SWOLF(구간시간+스트로크수), 100m 페이스, 영법 분포, 주간 볼륨, 세션 내 스플릿

## 작업 규칙
- 변경 후 항상 `flutter analyze` 통과 확인. 위젯/모델 변경 시 빌드 확인.
- 한 번에 한 마일스톤만. UI 전에 브릿지부터.
- 빌드: `flutter run -d <device-id>` / 네이티브: `cd android && ./gradlew assembleDebug`