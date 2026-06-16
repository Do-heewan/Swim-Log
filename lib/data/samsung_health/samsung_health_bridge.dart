import 'package:flutter/services.dart';

import 'models/swimming_log.dart';

/// Samsung Health Data SDK 네이티브 브릿지(MethodChannel) 래퍼.
///
/// 읽기 전용이며 실기기 + Samsung Health 6.30.2+ 에서만 동작한다.
/// 네이티브 측은 `MainActivity.kt` / `health/SamsungHealthBridge.kt`.
class SamsungHealthBridge {
  const SamsungHealthBridge();

  static const MethodChannel _channel = MethodChannel(
    'swim_log/samsung_health',
  );

  /// ExerciseType 읽기 권한을 요청한다. 동의(또는 이미 허용) 시 `true`.
  Future<bool> requestExercisePermission() async {
    final granted = await _channel.invokeMethod<bool>(
      'requestExercisePermission',
    );
    return granted ?? false;
  }

  /// 가장 최근 POOL_SWIMMING 세션의 [SwimmingLog]. 없으면 `null`.
  ///
  /// 권한 미허용·Samsung Health 미설치 등 네이티브 오류는 [PlatformException]으로
  /// 전파된다. 호출 측에서 처리한다.
  Future<SwimmingLog?> getLatestPoolSwimming() async {
    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      'getLatestPoolSwimming',
    );
    if (result == null) return null;
    return SwimmingLog.fromMap(result);
  }

  /// 채널이 돌려준 **가공 전** Map(디버그/덤프용). 모델 파싱을 건너뛴다.
  ///
  /// `swim-bridge-dump` 스킬의 raw JSON 출력에 사용한다. 없으면 `null`.
  Future<Map<String, dynamic>?> rawLatestPoolSwimming() {
    return _channel.invokeMapMethod<String, dynamic>('getLatestPoolSwimming');
  }
}
