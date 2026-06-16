---
name: swim-bridge-dump
description: 최근 수영 세션 1건을 Samsung Health Data SDK 브릿지로 읽어 raw JSON으로 출력해 데이터 구조와 연동을 검증한다. 브릿지 디버깅 시 사용.
---

# 수영 세션 덤프 (브릿지 검증)

UI 없이, 네이티브 브릿지가 실제 데이터를 반환하는지 확인한다.

1. MethodChannel로 `readLatestSwimSession`을 호출하는 임시 진입점(또는 디버그 화면)을 사용.
2. 반환된 SwimmingLog/SwimmingInterval/StrokeType을 가공 없이 pretty JSON으로 콘솔 출력.
3. 누락 필드(영법, 스트로크 수, SWOLF 계산용 값)가 있으면 표로 정리해 보고.
4. 연결된 기기에서 `flutter run -d <device>`로 실행하고 로그를 첨부.

데이터가 안 나오면: SH 개발자 모드 "데이터 읽기" 활성화 여부, 권한 동의,
SH 버전(6.30.2+), .aar 의존성/ProGuard keep 규칙부터 점검.
