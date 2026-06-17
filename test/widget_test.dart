// SwimmingLog 파생 지표(요약 카드 입력) 단위 테스트.
// 화면은 실기기 MethodChannel이 필요하므로, 순수 계산인 모델을 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:swim_log/data/samsung_health/models/swimming_log.dart';

void main() {
  // 50m 풀 / 3랩 / 자유형 2 + 접영 1 세션.
  final log = SwimmingLog.fromMap({
    'startTime': '2026-06-16T19:00:00.000Z',
    'endTime': '2026-06-16T19:22:00.000Z', // 경과 22분
    'exerciseType': 'POOL_SWIMMING',
    'poolLength': 50,
    'poolLengthUnit': 'meter',
    'totalDistance': 150.0,
    'totalDuration': 270000, // 순수 수영 4:30
    'intervals': [
      {'interval': 1, 'durationMillis': 30000, 'strokeCount': 18, 'strokeType': 'FREESTYLE'},
      {'interval': 1, 'durationMillis': 32000, 'strokeCount': 19, 'strokeType': 'FREESTYLE'},
      {'interval': 2, 'durationMillis': 40000, 'strokeCount': 16, 'strokeType': 'BUTTERFLY'},
    ],
  });

  test('랩 수 = intervals 길이', () {
    expect(log.lengthCount, 3);
  });

  test('휴식 = 경과 − 순수 수영', () {
    expect(log.elapsed, const Duration(minutes: 22));
    expect(log.restDuration, const Duration(minutes: 17, seconds: 30));
  });

  test('100m 페이스 = 순수시간을 거리로 환산', () {
    // 270000ms * 100 / 150m = 180000ms = 3:00
    expect(log.pacePer100m, const Duration(minutes: 3));
  });

  test('평균 SWOLF = 랩 SWOLF 산술평균', () {
    // (48 + 51 + 56) / 3 = 51.666...
    expect(log.averageSwolf, closeTo(51.67, 0.01));
  });

  test('영법 분포는 랩 수 내림차순', () {
    expect(log.strokeDistribution, {
      StrokeType.freestyle: 2,
      StrokeType.butterfly: 1,
    });
    expect(log.strokeDistribution.keys.first, StrokeType.freestyle);
  });

  test('거리/시간 미상이면 페이스는 null', () {
    final partial = SwimmingLog.fromMap({
      'startTime': '2026-06-16T19:00:00.000Z',
      'endTime': '2026-06-16T19:22:00.000Z',
      'poolLength': 50,
      'intervals': const [],
    });
    expect(partial.pacePer100m, isNull);
    expect(partial.averageSwolf, isNull);
    expect(partial.restDuration, isNull);
  });
}
