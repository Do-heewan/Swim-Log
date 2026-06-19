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

private fun SwimmingLog.SwimmingInterval.toMap(): Map<String, Any?> = mapOf(
    "interval" to interval,
    "durationMillis" to duration.toMillis(),
    "strokeCount" to strokeCount,
    "strokeType" to strokeType.name,
)

private fun Instant.toIso(): String = toString()
