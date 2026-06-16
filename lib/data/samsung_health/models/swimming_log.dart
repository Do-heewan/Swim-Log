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

  const SwimmingLog({
    required this.startTime,
    required this.endTime,
    required this.exerciseType,
    required this.poolLength,
    required this.poolLengthUnit,
    required this.totalDistance,
    required this.totalDuration,
    required this.intervals,
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
    );
  }
}
