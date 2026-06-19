/// Samsung Health Data SDK가 반환하는 수영 데이터의 Dart 모델.
///
/// 네이티브 브릿지(`SwimmingLogMapper.kt`)가 만든 중첩 Map과 1:1로 대응한다.
/// 읽기 전용 — Samsung Health에 다시 쓰지 않는다.
library;

/// 영법 타입. SDK `DataType.ExerciseType.StrokeType`과 1:1.
enum StrokeType {
  undefined,
  butterfly,
  backstroke,
  freestyle,
  breaststroke,
  kickBoard,
  mixed;

  /// 네이티브 enum 이름(예: `"KICK_BOARD"`)을 매핑. 알 수 없으면 [undefined].
  static StrokeType fromName(String? name) {
    switch (name) {
      case 'BUTTERFLY':
        return StrokeType.butterfly;
      case 'BACKSTROKE':
        return StrokeType.backstroke;
      case 'FREESTYLE':
        return StrokeType.freestyle;
      case 'BREASTSTROKE':
        return StrokeType.breaststroke;
      case 'KICK_BOARD':
        return StrokeType.kickBoard;
      case 'MIXED':
        return StrokeType.mixed;
      case 'UNDEFINED':
      default:
        return StrokeType.undefined;
    }
  }
}

/// 한 수영 구간(반복 세트 그룹). SWOLF 계산의 입력 단위.
class SwimmingInterval {
  /// 세트 그룹 번호(SDK `SwimmingInterval.interval`) — 반복 세트 묶음 id.
  /// 라이브 확인: 한 entry = 풀 길이 1바퀴(랩). 연속 세트면 전 항목이 동일 값(예: 모두 1).
  final int interval;
  final Duration duration;
  final int strokeCount;
  final StrokeType strokeType;

  const SwimmingInterval({
    required this.interval,
    required this.duration,
    required this.strokeCount,
    required this.strokeType,
  });

  /// SWOLF = 구간 시간(초) + 스트로크 수. 낮을수록 효율적.
  int get swolf => duration.inSeconds + strokeCount;

  factory SwimmingInterval.fromMap(Map<dynamic, dynamic> map) {
    return SwimmingInterval(
      interval: (map['interval'] as num?)?.toInt() ?? 0,
      duration: Duration(
        milliseconds: (map['durationMillis'] as num?)?.toInt() ?? 0,
      ),
      strokeCount: (map['strokeCount'] as num?)?.toInt() ?? 0,
      strokeType: StrokeType.fromName(map['strokeType'] as String?),
    );
  }
}

/// 한 수영 세션의 전체 기록.
class SwimmingLog {
  final DateTime startTime;
  final DateTime endTime;

  /// SDK `PredefinedExerciseType` 이름(예: `"POOL_SWIMMING"`).
  final String exerciseType;

  final int poolLength;

  /// `"meter"` 또는 `"yard"` — SDK가 String으로 제공(enum 아님).
  final String poolLengthUnit;

  final double? totalDistance;
  final Duration? totalDuration;
  final List<SwimmingInterval> intervals;

  /// 세션 평균 심박(bpm). SDK가 제공하지 않으면 `null`.
  final double? avgHeartRate;

  /// 세션 최대 심박(bpm). 없으면 `null`.
  final double? maxHeartRate;

  /// 세션 구간의 심박(bpm) 시계열. 심박 권한이 없거나 기록이 없으면 빈 리스트.
  /// SwimmingInterval에는 심박이 없어 랩별 심박은 제공하지 않는다.
  final List<int> heartRateSeries;

  const SwimmingLog({
    required this.startTime,
    required this.endTime,
    required this.exerciseType,
    required this.poolLength,
    required this.poolLengthUnit,
    required this.totalDistance,
    required this.totalDuration,
    required this.intervals,
    this.avgHeartRate,
    this.maxHeartRate,
    this.heartRateSeries = const [],
  });

  factory SwimmingLog.fromMap(Map<dynamic, dynamic> map) {
    final rawIntervals = (map['intervals'] as List<dynamic>?) ?? const [];
    return SwimmingLog(
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      exerciseType: (map['exerciseType'] as String?) ?? 'POOL_SWIMMING',
      poolLength: (map['poolLength'] as num?)?.toInt() ?? 0,
      poolLengthUnit: (map['poolLengthUnit'] as String?) ?? 'meter',
      totalDistance: (map['totalDistance'] as num?)?.toDouble(),
      totalDuration: map['totalDuration'] == null
          ? null
          : Duration(milliseconds: (map['totalDuration'] as num).toInt()),
      intervals: rawIntervals
          .map((e) => SwimmingInterval.fromMap(e as Map<dynamic, dynamic>))
          .toList(growable: false),
      avgHeartRate: (map['meanHeartRate'] as num?)?.toDouble(),
      maxHeartRate: (map['maxHeartRate'] as num?)?.toDouble(),
      heartRateSeries: ((map['heartRateSeries'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
    );
  }

  // ── 파생 지표 (요약 카드/분석용) ────────────────────────────────
  // SDK 원본값에서 계산만 한다. Samsung Health에 다시 쓰지 않는다.

  /// 랩(= 풀 1바퀴) 개수.
  int get lengthCount => intervals.length;

  /// 시작~종료 벽시계 경과 시간(휴식 포함).
  Duration get elapsed => endTime.difference(startTime);

  /// 휴식 시간 = 전체 경과 − 순수 수영 시간. [totalDuration]이 없으면 `null`.
  /// 음수가 나오면 0으로 보정한다(데이터 오차 방어).
  Duration? get restDuration {
    final swim = totalDuration;
    if (swim == null) return null;
    final rest = elapsed - swim;
    return rest.isNegative ? Duration.zero : rest;
  }

  /// 100m 평균 페이스. 순수 수영 시간을 거리로 환산. 거리/시간 미상이면 `null`.
  Duration? get pacePer100m {
    final dist = totalDistance;
    final swim = totalDuration;
    if (dist == null || dist <= 0 || swim == null) return null;
    return Duration(milliseconds: (swim.inMilliseconds * 100 / dist).round());
  }

  /// 세션 평균 SWOLF(랩별 SWOLF의 산술평균). 구간이 없으면 `null`.
  double? get averageSwolf {
    if (intervals.isEmpty) return null;
    final total = intervals.fold<int>(0, (sum, i) => sum + i.swolf);
    return total / intervals.length;
  }

  /// 영법별 랩 수 분포. 랩 수가 많은 순으로 정렬해 반환.
  Map<StrokeType, int> get strokeDistribution {
    final counts = <StrokeType, int>{};
    for (final i in intervals) {
      counts.update(i.strokeType, (v) => v + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }
}
