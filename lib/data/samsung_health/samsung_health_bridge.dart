import 'package:flutter/services.dart';

import 'models/swim_session_summary.dart';
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

  /// [start]~[end](exclusive) 구간의 POOL_SWIMMING 세션 요약 리스트(최신순).
  ///
  /// [start]/[end]는 **로컬** 기준 경계다(예: 그 달 1일 00:00 ~ 다음 달 1일 00:00).
  /// 캘린더 한 달 분량을 읽을 때 사용한다.
  Future<List<SwimSessionSummary>> getPoolSwimmingSessions(
    DateTime start,
    DateTime end,
  ) async {
    final list = await _channel.invokeListMethod<dynamic>(
      'getPoolSwimmingSessions',
      {'start': _localIso(start), 'end': _localIso(end)},
    );
    if (list == null) return const [];
    return list
        .map((e) => SwimSessionSummary.fromMap(e as Map<dynamic, dynamic>))
        .toList(growable: false);
  }

  /// 요약에서 고른 세션 1건의 전체 [SwimmingLog]. 없으면 `null`.
  ///
  /// [startTimeRaw]는 [SwimSessionSummary.startTimeRaw](네이티브가 준 원본 ISO)를
  /// 그대로 넘겨야 시작 시각이 정확히 일치한다.
  Future<SwimmingLog?> getPoolSwimmingDetail(String startTimeRaw) async {
    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      'getPoolSwimmingDetail',
      {'startTime': startTimeRaw},
    );
    if (result == null) return null;
    return SwimmingLog.fromMap(result);
  }

  /// 네이티브 `LocalDateTime.parse`가 받는 형식(타임존 접미사 없는 ISO-8601).
  /// [dt]는 로컬 DateTime이어야 한다.
  static String _localIso(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
        '${two(local.day)}T${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
