/// 캘린더/목록용 수영 세션 경량 요약.
///
/// 네이티브 `SwimmingLogMapper.toSummaryMap()`이 만든 Map과 1:1로 대응한다.
/// 상세(구간·심박)는 담지 않는다 — 세션을 선택하면 [startTimeRaw]를 키로
/// `getPoolSwimmingDetail`을 호출해 전체 [SwimmingLog]를 따로 읽는다.
library;

class SwimSessionSummary {
  /// 네이티브가 준 시작 시각 원본 ISO 문자열. **상세 재조회의 키**이므로
  /// 가공하지 않고 그대로 보관했다가 되돌려준다.
  final String startTimeRaw;

  /// 표시용 시작 시각(로컬). 캘린더의 "어느 날" 판정도 이 값의 로컬 날짜로 한다.
  final DateTime startTime;
  final DateTime endTime;

  final int poolLength;
  final String poolLengthUnit;
  final double? totalDistance;
  final Duration? totalDuration;

  /// 랩(= 풀 1바퀴) 개수.
  final int lengthCount;

  const SwimSessionSummary({
    required this.startTimeRaw,
    required this.startTime,
    required this.endTime,
    required this.poolLength,
    required this.poolLengthUnit,
    required this.totalDistance,
    required this.totalDuration,
    required this.lengthCount,
  });

  factory SwimSessionSummary.fromMap(Map<dynamic, dynamic> map) {
    final rawStart = map['startTime'] as String;
    return SwimSessionSummary(
      startTimeRaw: rawStart,
      startTime: DateTime.parse(rawStart).toLocal(),
      endTime: DateTime.parse(map['endTime'] as String).toLocal(),
      poolLength: (map['poolLength'] as num?)?.toInt() ?? 0,
      poolLengthUnit: (map['poolLengthUnit'] as String?) ?? 'meter',
      totalDistance: (map['totalDistance'] as num?)?.toDouble(),
      totalDuration: map['totalDuration'] == null
          ? null
          : Duration(milliseconds: (map['totalDuration'] as num).toInt()),
      lengthCount: (map['lengthCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 캘린더 그룹핑용 로컬 날짜(시·분 제거).
  DateTime get localDate =>
      DateTime(startTime.year, startTime.month, startTime.day);

  /// 거리 — 원본이 없으면 풀 길이 × 랩 수로 보정.
  double get distance => totalDistance ?? (poolLength * lengthCount).toDouble();

  /// 100m 평균 페이스. 거리/시간 미상이면 `null`.
  Duration? get pacePer100m {
    final swim = totalDuration;
    if (swim == null || distance <= 0) return null;
    return Duration(
      milliseconds: (swim.inMilliseconds * 100 / distance).round(),
    );
  }
}
