# android/app/libs/

Samsung Health Data SDK의 AAR을 여기에 둔다.

- 파일: `samsung-health-data-api-*.aar` (예: `samsung-health-data-api-1.1.0.aar`)
- 받는 곳: https://developer.samsung.com/health/data (약관 동의 필요)
- 이 바이너리는 **git에 커밋하지 않는다**(`.gitignore`로 제외). 클론 후 직접 배치할 것.
- `build.gradle.kts`가 `libs/*.aar`를 fileTree로 포함한다.
- 읽기 테스트는 Samsung Health 앱에서 **개발자 모드(Data Read)** 만 켜면 됨(읽기 전용은 파트너 승인 불필요).
