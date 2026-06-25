package com.noh.swim_log.health

import com.samsung.android.sdk.health.data.data.entries.ExerciseSession
import com.samsung.android.sdk.health.data.data.entries.SwimmingLog
import java.time.Instant

/**
 * 수영 [ExerciseSession] → MethodChannel로 보낼 수 있는 중첩 Map.
 * Dart `SwimmingLog.fromMap`과 키가 1:1로 일치한다.
 *
 * 직렬화 규칙: Instant → ISO-8601 String, Duration → 밀리초(Long),
 * enum(StrokeType / PredefinedExerciseType) → name String, Float → double로 전송됨.
 *
 * [heartRateSeries]는 세션 구간의 심박(bpm) 시계열(권한 없으면 빈 리스트).
 * 세션 평균/최대 심박은 ExerciseSession 자체 필드에서 온다.
 */
fun ExerciseSession.toSwimmingLogMap(heartRateSeries: List<Int>): Map<String, Any?> {
    val log: SwimmingLog? = swimmingLog
    return mapOf(
        "startTime" to startTime.toIso(),
        "endTime" to endTime.toIso(),
        "exerciseType" to exerciseType.name,
        "poolLength" to log?.poolLength,
        "poolLengthUnit" to log?.poolLengthUnit,
        "totalDistance" to log?.totalDistance,
        "totalDuration" to log?.totalDuration?.toMillis(),
        "intervals" to (log?.swimmingIntervals?.map { it.toMap() } ?: emptyList()),
        // 심박 — SwimmingInterval에는 심박이 없으므로 세션 단위 집계 + 시계열만 제공한다.
        "meanHeartRate" to meanHeartRate,
        "maxHeartRate" to maxHeartRate,
        "minHeartRate" to minHeartRate,
        "heartRateSeries" to heartRateSeries,
    )
}

/**
 * 캘린더/목록용 경량 요약 Map. 상세(구간·심박 시계열)는 제외해 전송량을 줄인다.
 * Dart `SwimSessionSummary.fromMap`과 키가 1:1로 일치한다.
 *
 * [startTime]은 상세 재조회의 키이므로, Dart는 이 문자열을 그대로 되돌려준다.
 */
fun ExerciseSession.toSummaryMap(): Map<String, Any?> {
    val log: SwimmingLog? = swimmingLog
    return mapOf(
        "startTime" to startTime.toIso(),
        "endTime" to endTime.toIso(),
        "poolLength" to log?.poolLength,
        "poolLengthUnit" to log?.poolLengthUnit,
        "totalDistance" to log?.totalDistance,
        "totalDuration" to log?.totalDuration?.toMillis(),
        "lengthCount" to (log?.swimmingIntervals?.size ?: 0),
    )
}

private fun SwimmingLog.SwimmingInterval.toMap(): Map<String, Any?> = mapOf(
    "interval" to interval,
    "durationMillis" to duration.toMillis(),
    "strokeCount" to strokeCount,
    "strokeType" to strokeType.name,
)

private fun Instant.toIso(): String = toString()
