// SwimmingLog(브릿지 원본) → SwimSession(화면 모델) 어댑터 검증.
// 디자인 본문(SwimSessionView)이 의존하는 파생값들을 보장한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:swim_log/data/samsung_health/models/swimming_log.dart';
import 'package:swim_log/features/session/models/swim_session.dart';

SwimmingLog _buildLog() => SwimmingLog.fromMap({
  'startTime': '2026-06-16T19:00:00.000Z',
  'endTime': '2026-06-16T19:22:00.000Z', // 경과 22분
  'exerciseType': 'POOL_SWIMMING',
  'poolLength': 50,
  'poolLengthUnit': 'meter',
  'totalDistance': 150.0,
  'totalDuration': 270000, // 순수 4:30
  'intervals': [
    {'interval': 1, 'durationMillis': 30000, 'strokeCount': 18, 'strokeType': 'FREESTYLE'},
    {'interval': 1, 'durationMillis': 32000, 'strokeCount': 19, 'strokeType': 'FREESTYLE'},
    {'interval': 2, 'durationMillis': 40000, 'strokeCount': 16, 'strokeType': 'BUTTERFLY'},
  ],
});

void main() {
  test('랩은 구간 수만큼, 1-based 인덱스로 매핑', () {
    final s = SwimSession.fromSwimmingLog(_buildLog());
    expect(s.laps.length, 3);
    expect(s.laps.first.index, 1);
    expect(s.laps.last.index, 3);
    expect(s.laps.first.distance, 50.0); // 랩 거리 = 풀 길이
  });

  test('심박 키가 없으면 비어 있음', () {
    final s = SwimSession.fromSwimmingLog(_buildLog());
    expect(s.hasHeartRate, isFalse);
    expect(s.avgHeartRate, isNull);
    expect(s.heartRateSeries, isEmpty);
    expect(s.laps.first.avgHeartRate, isNull);
  });

  test('심박 집계/시계열은 전달, 랩별 심박은 여전히 없음', () {
    final log = SwimmingLog.fromMap({
      'startTime': '2026-06-16T19:00:00.000Z',
      'endTime': '2026-06-16T19:22:00.000Z',
      'poolLength': 50,
      'totalDistance': 150.0,
      'totalDuration': 270000,
      'intervals': [
        {'interval': 1, 'durationMillis': 30000, 'strokeCount': 18, 'strokeType': 'FREESTYLE'},
      ],
      'meanHeartRate': 142.6, // Float→double로 전송됨
      'maxHeartRate': 171.0,
      'heartRateSeries': [120, 134, 150, 160],
    });
    final s = SwimSession.fromSwimmingLog(log);
    expect(s.hasHeartRate, isTrue);
    expect(s.avgHeartRate, 143); // 반올림
    expect(s.maxHeartRate, 171);
    expect(s.heartRateSeries, [120, 134, 150, 160]);
    expect(s.laps.first.avgHeartRate, isNull); // 랩별은 SDK 미제공
  });

  test('100m 페이스(초) = 순수시간 ÷ (거리/100)', () {
    final s = SwimSession.fromSwimmingLog(_buildLog());
    // 270초 ÷ (150/100) = 180초
    expect(s.avgPacePer100Sec, closeTo(180, 0.001));
  });

  test('영법 분포는 합계 1.0', () {
    final s = SwimSession.fromSwimmingLog(_buildLog());
    final sum = s.strokeDistribution.values.fold<double>(0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));
    expect(s.strokeDistribution[StrokeType.freestyle], closeTo(2 / 3, 1e-9));
  });

  test('가장 빠른 랩 = 시간이 가장 짧은 랩', () {
    final s = SwimSession.fromSwimmingLog(_buildLog());
    expect(s.fastestLap?.index, 1); // 30초로 최단
  });

  test('거리/시간 누락 시 폴백(거리=풀×랩수, 시간=경과)', () {
    final log = SwimmingLog.fromMap({
      'startTime': '2026-06-16T19:00:00.000Z',
      'endTime': '2026-06-16T19:10:00.000Z',
      'poolLength': 25,
      'intervals': [
        {'interval': 1, 'durationMillis': 20000, 'strokeCount': 10, 'strokeType': 'FREESTYLE'},
        {'interval': 1, 'durationMillis': 22000, 'strokeCount': 11, 'strokeType': 'FREESTYLE'},
      ],
    });
    final s = SwimSession.fromSwimmingLog(log);
    expect(s.totalDistance, 50.0); // 25m × 2랩
    expect(s.activeTime, const Duration(minutes: 10)); // 경과로 폴백
  });
}
