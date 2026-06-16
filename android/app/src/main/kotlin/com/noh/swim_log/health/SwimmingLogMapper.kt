package com.noh.swim_log.health

import com.samsung.android.sdk.health.data.data.entries.ExerciseSession
import com.samsung.android.sdk.health.data.data.entries.SwimmingLog
import java.time.Instant

/**
 * 수영 [ExerciseSession] → MethodChannel로 보낼 수 있는 중첩 Map.
 * Dart `SwimmingLog.fromMap`과 키가 1:1로 일치한다.
 *
 * 직렬화 규칙: Instant → ISO-8601 String, Duration → 밀리초(Long),
 * enum(StrokeType / PredefinedExerciseType) → name String.
 */
fun ExerciseSession.toSwimmingLogMap(): Map<String, Any?> {
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
    )
}

private fun SwimmingLog.SwimmingInterval.toMap(): Map<String, Any?> = mapOf(
    "interval" to interval,
    "durationMillis" to duration.toMillis(),
    "strokeCount" to strokeCount,
    "strokeType" to strokeType.name,
)

private fun Instant.toIso(): String = toString()
