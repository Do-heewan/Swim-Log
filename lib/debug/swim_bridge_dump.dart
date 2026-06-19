import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/samsung_health/samsung_health_bridge.dart';

/// 실기기에서 브릿지가 실제 데이터를 반환하는지 확인하는 **dev 전용** 덤프.
///
/// UI 없이 동작하며 `flutter run --dart-define=DUMP_SWIM=true`에서만 호출된다.
/// (`swim-bridge-dump` 스킬) 출력은 `debugPrint` → logcat의 `I/flutter`.
const _tag = '[swim-dump]';

Future<void> dumpLatestPoolSwimming() async {
  const bridge = SamsungHealthBridge();

  try {
    final granted = await bridge.requestExercisePermission();
    debugPrint('$_tag ExerciseType 읽기 권한: $granted');
    if (!granted) {
      debugPrint('$_tag 권한 거부 — 중단. (SH 개발자 모드 + 동의 확인)');
      return;
    }

    final raw = await bridge.rawLatestPoolSwimming();
    if (raw == null) {
      debugPrint('$_tag 윈도우 내 POOL_SWIMMING 세션 없음 (null).');
      return;
    }

    final pretty = const JsonEncoder.withIndent('  ').convert(raw);
    debugPrint('$_tag 최근 POOL_SWIMMING raw JSON:');
    // debugPrint는 긴 줄을 자르므로 줄 단위로 출력.
    for (final line in pretty.split('\n')) {
      debugPrint('$_tag $line');
    }

    // 진단 요약 — SWOLF 입력(구간 시간/스트로크 수)이 실제로 채워졌는지 확인.
    final intervals = (raw['intervals'] as List<dynamic>?) ?? const [];
    final strokeTypes = intervals
        .map((e) => (e as Map)['strokeType'])
        .toSet()
        .toList();
    final missingSwolfInputs = intervals.any((e) {
      final m = e as Map;
      return m['strokeCount'] == null || m['durationMillis'] == null;
    });
    debugPrint(
      '$_tag 진단 | poolLength=${raw['poolLength']} ${raw['poolLengthUnit']} '
      '| totalDistance=${raw['totalDistance']} '
      '| totalDuration=${raw['totalDuration']}ms '
      '| intervals=${intervals.length} | strokeTypes=$strokeTypes '
      '| SWOLF입력누락=$missingSwolfInputs',
    );

    // 심박 진단 — 세션 집계(EXERCISE 권한)와 시계열(HEART_RATE 권한)이 채워졌는지 확인.
    final hrSeries = (raw['heartRateSeries'] as List<dynamic>?) ?? const [];
    final hrMin = hrSeries.isEmpty
        ? null
        : hrSeries.cast<num>().reduce((a, b) => a < b ? a : b);
    final hrMax = hrSeries.isEmpty
        ? null
        : hrSeries.cast<num>().reduce((a, b) => a > b ? a : b);
    debugPrint(
      '$_tag 심박 | meanHeartRate=${raw['meanHeartRate']} '
      '| maxHeartRate=${raw['maxHeartRate']} '
      '| minHeartRate=${raw['minHeartRate']} '
      '| heartRateSeries=${hrSeries.length}샘플'
      '${hrSeries.isEmpty ? ' (없음 — 권한 미동의이거나 워치가 수영 중 심박 미기록)' : ' (범위 $hrMin~$hrMax bpm)'}',
    );
  } on PlatformException catch (e) {
    // PLATFORM_NOT_INSTALLED / OLD_VERSION_PLATFORM / ERR_NO_USER_PERMISSION / 2003 등.
    debugPrint('$_tag 브릿지 오류 [${e.code}] ${e.message} | details=${e.details}');
  } catch (e, st) {
    debugPrint('$_tag 예기치 못한 오류: $e\n$st');
  }
}
