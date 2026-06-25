// 네이티브 요약 Map → SwimSessionSummary 파싱/파생값 검증.
// 캘린더 목록이 의존하는 계약(거리 폴백·페이스·상세조회 키 보존)을 보장한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:swim_log/data/samsung_health/models/swim_session_summary.dart';

void main() {
  test('요약 파싱 + startTimeRaw는 원본 그대로 보존(상세조회 키)', () {
    const raw = '2026-06-16T10:00:00Z';
    final s = SwimSessionSummary.fromMap({
      'startTime': raw,
      'endTime': '2026-06-16T10:30:00Z',
      'poolLength': 50,
      'poolLengthUnit': 'meter',
      'totalDistance': 1500.0,
      'totalDuration': 1800000, // 30분
      'lengthCount': 30,
    });
    expect(s.startTimeRaw, raw); // 가공 없이 그대로
    expect(s.distance, 1500.0);
    expect(s.lengthCount, 30);
    // 1500m를 30분(1800초) → 100m당 120초 = 2:00
    expect(s.pacePer100m, const Duration(seconds: 120));
  });

  test('거리 누락 시 풀 길이 × 랩 수로 보정', () {
    final s = SwimSessionSummary.fromMap({
      'startTime': '2026-06-16T10:00:00Z',
      'endTime': '2026-06-16T10:30:00Z',
      'poolLength': 25,
      'lengthCount': 40,
      // totalDistance 없음
    });
    expect(s.distance, 1000.0); // 25 × 40
  });

  test('시간 미상이면 페이스는 null', () {
    final s = SwimSessionSummary.fromMap({
      'startTime': '2026-06-16T10:00:00Z',
      'endTime': '2026-06-16T10:30:00Z',
      'poolLength': 50,
      'totalDistance': 1000.0,
      'lengthCount': 20,
      // totalDuration 없음
    });
    expect(s.pacePer100m, isNull);
  });

  test('localDate는 시·분을 버린 로컬 날짜', () {
    final s = SwimSessionSummary.fromMap({
      'startTime': '2026-06-16T10:00:00Z',
      'endTime': '2026-06-16T10:30:00Z',
      'poolLength': 50,
      'lengthCount': 10,
    });
    final local = DateTime.parse('2026-06-16T10:00:00Z').toLocal();
    expect(s.localDate, DateTime(local.year, local.month, local.day));
  });
}
