---
name: swim-bridge-dump
description: 최근 수영 세션 1건을 Samsung Health Data SDK 브릿지로 읽어 raw JSON으로 출력해 데이터 구조와 연동을 검증한다. 브릿지 디버깅 시 사용.
---

# 수영 세션 덤프 (브릿지 검증)

UI 없이, 네이티브 브릿지가 실제 데이터를 반환하는지 확인한다.

1. `flutter run -d <device> --dart-define=DUMP_SWIM=true`로 덤프 진입점(`lib/debug/swim_bridge_dump.dart`)을 실행.
   내부적으로 MethodChannel `swim_log/samsung_health`의 `getLatestPoolSwimming`/`rawLatestPoolSwimming`을 호출한다.
2. 반환된 SwimmingLog/SwimmingInterval/StrokeType을 가공 없이 pretty JSON으로 콘솔 출력.
3. 누락 필드(영법, 스트로크 수, SWOLF 계산용 값)가 있으면 표로 정리해 보고.
4. 연결된 기기에서 `flutter run -d <device>`로 실행하고 로그를 첨부.

데이터가 안 나오면: SH 개발자 모드 "데이터 읽기" 활성화 여부, 권한 동의,
SH 버전(6.30.2+), .aar 의존성/ProGuard keep 규칙부터 점검.
읽기 전용은 개발자 모드만 켜면 되고 파트너 승인은 불필요(쓰기에만 access code 필요).
개발자 모드: SH → ⋮ → 설정 → Samsung Health 정보 → 버전 줄 10회+ 탭 → Developer mode (Samsung Health Data SDK).
