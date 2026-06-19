// swim_session.dart
// 화면(추세 리포트) 전용 프레젠테이션 모델.
// 데이터 레이어의 SwimmingLog(브릿지 원본)를 이 모델로 정규화해 UI에 주입한다.
//
// 심박(heart rate)은 세션 평균/최대 + 운동 중 시계열을 브릿지가 제공한다(선택값).
// 시계열이 없으면 화면이 심박 카드를 생략한다. 랩별 심박은 SDK 미제공이라 표시하지 않는다.
// 심박 존(저/중/고강도)은 삼성헬스가 최대심박·구간을 SDK로 노출하지 않아 다루지 않는다.

import '../../../data/samsung_health/models/swimming_log.dart';

export '../../../data/samsung_health/models/swimming_log.dart' show StrokeType;

/// 영법 한글 라벨.
extension StrokeTypeLabel on StrokeType {
  String get ko {
    switch (this) {
      case StrokeType.freestyle:
        return '자유형';
      case StrokeType.butterfly:
        return '접영';
      case StrokeType.backstroke:
        return '배영';
      case StrokeType.breaststroke:
        return '평영';
      case StrokeType.kickBoard:
        return '킥판';
      case StrokeType.mixed:
        return '혼합';
      case StrokeType.undefined:
        return '기타';
    }
  }
}

/// 100m(또는 풀 기준) 스플릿 한 구간.
class SwimLap {
  final int index; // 1-based
  final StrokeType stroke;
  final Duration time; // 이 랩의 소요 시간
  final int strokes; // 스트로크 수
  final int swolf; // SWOLF = (랩 시간 초) + 스트로크 수
  final int? avgHeartRate; // 평균 심박 (bpm). 없으면 null
  final double distance; // m

  const SwimLap({
    required this.index,
    required this.stroke,
    required this.time,
    required this.strokes,
    required this.swolf,
    required this.avgHeartRate,
    required this.distance,
  });

  double get seconds => time.inMilliseconds / 1000.0;
}

/// 한 번의 수영 세션 전체 (화면 입력).
class SwimSession {
  final DateTime startTime;
  final Duration elapsed; // 전체 경과 시간 (휴식 포함)
  final Duration activeTime; // 순수 수영 시간
  final double totalDistance; // m
  final int poolLength; // m (예: 25, 50)
  final double avgPacePer100Sec; // 평균 100m 페이스 (초)
  final int avgSwolf;
  final int? avgHeartRate; // 없으면 null
  final int? maxHeartRate; // 없으면 null
  final List<SwimLap> laps;
  final List<int> heartRateSeries; // 세션 전체 심박 샘플. 없으면 빈 리스트
  final Map<StrokeType, double> strokeDistribution; // 합계 1.0

  const SwimSession({
    required this.startTime,
    required this.elapsed,
    required this.activeTime,
    required this.totalDistance,
    required this.poolLength,
    required this.avgPacePer100Sec,
    required this.avgSwolf,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.laps,
    required this.heartRateSeries,
    required this.strokeDistribution,
  });

  Duration get restTime => elapsed - activeTime;

  /// 심박 데이터 보유 여부 — 화면이 심박 관련 요소 표시를 결정한다.
  bool get hasHeartRate => heartRateSeries.isNotEmpty;

  /// 브릿지 원본 [SwimmingLog]에서 화면용 세션을 만든다.
  ///
  /// 심박 평균/최대/시계열은 [SwimmingLog]에서 그대로 옮기고,
  /// 랩별 심박은 SDK가 제공하지 않으므로 null로 둔다.
  factory SwimSession.fromSwimmingLog(SwimmingLog log) {
    final poolLength = log.poolLength;
    final active = log.totalDuration ?? log.elapsed;
    final distance =
        log.totalDistance ?? (poolLength * log.lengthCount).toDouble();

    final laps = <SwimLap>[
      for (var i = 0; i < log.intervals.length; i++)
        SwimLap(
          index: i + 1,
          stroke: log.intervals[i].strokeType,
          time: log.intervals[i].duration,
          strokes: log.intervals[i].strokeCount,
          swolf: log.intervals[i].swolf,
          avgHeartRate: null,
          distance: poolLength.toDouble(),
        ),
    ];

    final avgPace = distance > 0
        ? active.inMilliseconds / 1000.0 / (distance / 100.0)
        : 0.0;

    // 영법 분포(랩 수 기준, 합계 1.0).
    final counts = log.strokeDistribution;
    final totalLaps = log.lengthCount == 0 ? 1 : log.lengthCount;
    final distribution = <StrokeType, double>{
      for (final e in counts.entries) e.key: e.value / totalLaps,
    };

    return SwimSession(
      startTime: log.startTime,
      elapsed: log.elapsed,
      activeTime: active,
      totalDistance: distance,
      poolLength: poolLength,
      avgPacePer100Sec: avgPace,
      avgSwolf: (log.averageSwolf ?? 0).round(),
      avgHeartRate: log.avgHeartRate?.round(),
      maxHeartRate: log.maxHeartRate?.round(),
      laps: laps,
      heartRateSeries: log.heartRateSeries,
      strokeDistribution: distribution,
    );
  }

  /// 가장 빠른 랩 (BEST 배지 대상). 랩이 없으면 null.
  SwimLap? get fastestLap => laps.isEmpty
      ? null
      : laps.reduce((a, b) => a.seconds <= b.seconds ? a : b);

  /// 후반부 피로도 인사이트: 마지막 N랩과 첫 N랩의 평균 페이스·SWOLF 차이.
  ({int paceDeltaSec, int swolfDelta}) fatigue({int window = 5}) {
    if (laps.length < window * 2) {
      return (paceDeltaSec: 0, swolfDelta: 0);
    }
    final first = laps.take(window).toList();
    final last = laps.skip(laps.length - window).toList();
    double avg(List<SwimLap> l, double Function(SwimLap) f) =>
        l.map(f).reduce((a, b) => a + b) / l.length;
    final paceDelta =
        avg(last, (l) => l.seconds) - avg(first, (l) => l.seconds);
    final swolfDelta =
        avg(last, (l) => l.swolf.toDouble()) -
        avg(first, (l) => l.swolf.toDouble());
    return (paceDeltaSec: paceDelta.round(), swolfDelta: swolfDelta.round());
  }
}

/// 시간 포맷 헬퍼 (m:ss).
String formatMmSs(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatPace(double seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).round();
  return '$m:${s.toString().padLeft(2, '0')}';
}
