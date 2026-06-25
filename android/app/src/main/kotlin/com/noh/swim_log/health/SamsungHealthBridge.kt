package com.noh.swim_log.health

import android.app.Activity
import android.util.Log
import com.samsung.android.sdk.health.data.HealthDataService
import com.samsung.android.sdk.health.data.HealthDataStore
import com.samsung.android.sdk.health.data.data.HealthDataPoint
import com.samsung.android.sdk.health.data.data.entries.ExerciseSession
import com.samsung.android.sdk.health.data.error.ResolvablePlatformException
import com.samsung.android.sdk.health.data.permission.AccessType
import com.samsung.android.sdk.health.data.permission.Permission
import com.samsung.android.sdk.health.data.request.DataType
import com.samsung.android.sdk.health.data.request.DataTypes
import com.samsung.android.sdk.health.data.request.InstantTimeFilter
import com.samsung.android.sdk.health.data.request.LocalTimeFilter
import com.samsung.android.sdk.health.data.request.Ordering
import java.time.Instant
import java.time.LocalDateTime
import kotlin.math.roundToInt

/**
 * Samsung Health Data SDK 브릿지 (읽기 전용).
 *
 * Samsung Health에 쓰지 않는다. requestPermissions는 android.app.Activity를 받으므로
 * 기본 FlutterActivity로 충분하다.
 */
class SamsungHealthBridge(private val activity: Activity) {

    private val store: HealthDataStore by lazy {
        HealthDataService.getStore(activity.applicationContext)
    }

    private val exercisePermissions =
        setOf(Permission.of(DataTypes.EXERCISE, AccessType.READ))

    private val heartRatePermissions =
        setOf(Permission.of(DataTypes.HEART_RATE, AccessType.READ))

    // 한 번의 동의 화면에서 운동 + 심박을 함께 요청한다.
    private val allPermissions = exercisePermissions + heartRatePermissions

    /**
     * 읽기 권한 요청(운동 + 심박). EXERCISE는 필수, HEART_RATE는 선택이다.
     * 동의 후 **EXERCISE** 허용 여부를 반환한다(심박은 있으면 시계열을 추가로 제공).
     */
    suspend fun requestExercisePermission(): Boolean {
        if (!store.getGrantedPermissions(allPermissions).containsAll(allPermissions)) {
            try {
                // requestPermissions는 요청한 집합을 그대로 반환하므로, 동의 결과는 다시 조회한다.
                store.requestPermissions(allPermissions, activity)
            } catch (e: ResolvablePlatformException) {
                // Samsung Health 업데이트/설정 등 해결 가능한 상태면 해결 화면을 띄운다.
                if (e.hasResolution) e.resolve(activity)
                return false
            }
        }
        return store.getGrantedPermissions(exercisePermissions)
            .containsAll(exercisePermissions)
    }

    /** 심박 읽기 권한이 허용됐는지. */
    private suspend fun isHeartRateGranted(): Boolean =
        store.getGrantedPermissions(heartRatePermissions).containsAll(heartRatePermissions)

    /**
     * 최근 [lookbackDays]일 내 가장 최근 POOL_SWIMMING 세션을 JSON 직렬화 가능한 Map으로 반환.
     * 없으면 null.
     *
     * SDK read에 운동 타입 필터가 없어 EXERCISE 전체를 읽은 뒤 클라이언트에서 수영만 골라낸다.
     */
    suspend fun readLatestPoolSwimming(lookbackDays: Long = 90): Map<String, Any?>? {
        val end = LocalDateTime.now()
        val start = end.minusDays(lookbackDays)

        val request = DataTypes.EXERCISE.readDataRequestBuilder
            .setLocalTimeFilter(LocalTimeFilter.of(start, end))
            .setOrdering(Ordering.DESC)
            .build()

        Log.i(TAG, "readLatestPoolSwimming: querying $start .. $end")
        val points = store.readData(request).dataList
        val poolSessions = points.poolSwimmingSessions()
        val latest = poolSessions.maxByOrNull { it.startTime }

        // 세션 동안의 심박 시계열. 1차 출처는 운동 세션 자체의 로그(ExerciseSession.log) —
        // 운동 중 촘촘히 기록된 샘플이라 "이번 수영의 심박 추이"에 맞다(EXERCISE 권한만으로 충분).
        // 로그가 비어 있을 때만 패시브 HEART_RATE 쿼리로 폴백한다(일상 심박이라 세션 구간엔 희소).
        val logSeries = if (latest != null) extractSessionHeartRateSeries(latest) else emptyList()
        val heartRateSeries =
            if (logSeries.size >= 2) {
                logSeries
            } else if (latest != null && isHeartRateGranted()) {
                readHeartRateSeries(latest.startTime, latest.endTime)
            } else {
                logSeries
            }

        // 덤프가 비어있을 때 원인(권한은 됐는데 세션이 없는 건지 등)을 좁히기 위한 진단 로그.
        Log.i(
            TAG,
            "readLatestPoolSwimming: points=${points.size}, " +
                "poolSwimming=${poolSessions.size}, " +
                "intervals=${latest?.swimmingLog?.swimmingIntervals?.size ?: 0}, " +
                "logEntries=${latest?.log?.size ?: 0}, logHr=${logSeries.size}, " +
                "hrSamples=${heartRateSeries.size}",
        )

        return latest?.toSwimmingLogMap(heartRateSeries)
    }

    /**
     * [startIso]~[endIso](로컬 날짜·시각, ISO-8601) 구간의 모든 POOL_SWIMMING 세션을
     * **경량 요약** Map 리스트로 반환(최신순). 캘린더/목록용이라 심박·구간은 제외한다.
     */
    suspend fun readPoolSwimmingSessions(startIso: String, endIso: String): List<Map<String, Any?>> {
        val start = LocalDateTime.parse(startIso)
        val end = LocalDateTime.parse(endIso)

        val request = DataTypes.EXERCISE.readDataRequestBuilder
            .setLocalTimeFilter(LocalTimeFilter.of(start, end))
            .setOrdering(Ordering.DESC)
            .build()

        val sessions = store.readData(request).dataList
            .poolSwimmingSessions()
            .sortedByDescending { it.startTime }
        Log.i(TAG, "readPoolSwimmingSessions: $start..$end -> ${sessions.size} sessions")
        return sessions.map { it.toSummaryMap() }
    }

    /**
     * 시작 시각이 [startTimeIso](Instant ISO-8601)인 POOL_SWIMMING 세션 1건의 **전체 상세**
     * (구간 + 심박)를 반환. 없으면 null. 세션 시각 ±1일로 좁혀 읽는다.
     *
     * [startTimeIso]는 [readPoolSwimmingSessions]가 준 `startTime` 문자열을 그대로 넘긴다.
     */
    suspend fun readPoolSwimmingDetail(startTimeIso: String): Map<String, Any?>? {
        val target = Instant.parse(startTimeIso)
        val request = DataTypes.EXERCISE.readDataRequestBuilder
            .setInstantTimeFilter(
                InstantTimeFilter.of(target.minusSeconds(DAY_SECONDS), target.plusSeconds(DAY_SECONDS)),
            )
            .setOrdering(Ordering.DESC)
            .build()

        val session = store.readData(request).dataList
            .poolSwimmingSessions()
            .firstOrNull { it.startTime == target }
        if (session == null) {
            Log.w(TAG, "readPoolSwimmingDetail: no session matching $startTimeIso")
            return null
        }

        val logSeries = extractSessionHeartRateSeries(session)
        val heartRateSeries =
            if (logSeries.size >= 2) {
                logSeries
            } else if (isHeartRateGranted()) {
                readHeartRateSeries(session.startTime, session.endTime)
            } else {
                logSeries
            }
        return session.toSwimmingLogMap(heartRateSeries)
    }

    /** EXERCISE 데이터 포인트들에서 수영 로그가 있는 POOL_SWIMMING 세션만 펼쳐 추출. */
    private fun List<HealthDataPoint>.poolSwimmingSessions(): List<ExerciseSession> =
        mapNotNull { it.getValue(DataType.ExerciseType.SESSIONS) }
            .flatten()
            .filter {
                it.exerciseType ==
                    DataType.ExerciseType.PredefinedExerciseType.POOL_SWIMMING &&
                    it.swimmingLog != null
            }

    /**
     * 운동 세션 자체의 시계열 로그([ExerciseSession.log])에서 심박(bpm)을 시간순으로 추출.
     *
     * 워치가 운동 중 기록한 샘플이라 "이번 세션의 심박 추이"에 정확히 대응한다.
     * EXERCISE 읽기에 포함되므로 별도 HEART_RATE 권한이 필요 없다.
     */
    private fun extractSessionHeartRateSeries(session: ExerciseSession): List<Int> =
        session.log.orEmpty()
            .mapNotNull { entry ->
                val bpm = entry.heartRate?.roundToInt()
                if (bpm != null && bpm > 0) entry.timestamp to bpm else null
            }
            .sortedBy { it.first }
            .map { it.second }

    /**
     * [start]~[end] 구간의 심박(bpm) 시계열을 시간순으로 반환. 권한이 있을 때만 호출한다.
     *
     * 각 데이터 포인트의 세부 샘플([DataType.HeartRateType.SERIES_DATA])을 펼치고,
     * 세부 샘플이 없으면 포인트 대표값([DataType.HeartRateType.HEART_RATE])을 쓴다.
     */
    private suspend fun readHeartRateSeries(start: Instant, end: Instant): List<Int> {
        val request = DataTypes.HEART_RATE.readDataRequestBuilder
            .setInstantTimeFilter(InstantTimeFilter.of(start, end))
            .setOrdering(Ordering.ASC)
            .build()

        val points = store.readData(request).dataList
        val samples = mutableListOf<Pair<Instant, Int>>()
        for (point in points) {
            val series = point.getValue(DataType.HeartRateType.SERIES_DATA)
            if (!series.isNullOrEmpty()) {
                for (hr in series) {
                    val bpm = hr.heartRate.roundToInt()
                    if (bpm > 0) samples.add(hr.startTime to bpm)
                }
            } else {
                val bpm = point.getValue(DataType.HeartRateType.HEART_RATE)?.roundToInt()
                if (bpm != null && bpm > 0) samples.add(point.startTime to bpm)
            }
        }
        return samples.sortedBy { it.first }.map { it.second }
    }

    private companion object {
        const val TAG = "SamsungHealthBridge"
        const val DAY_SECONDS = 86_400L
    }
}
