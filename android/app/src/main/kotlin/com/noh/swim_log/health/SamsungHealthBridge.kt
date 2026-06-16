package com.noh.swim_log.health

import android.app.Activity
import com.samsung.android.sdk.health.data.HealthDataService
import com.samsung.android.sdk.health.data.HealthDataStore
import com.samsung.android.sdk.health.data.error.ResolvablePlatformException
import com.samsung.android.sdk.health.data.permission.AccessType
import com.samsung.android.sdk.health.data.permission.Permission
import com.samsung.android.sdk.health.data.request.DataType
import com.samsung.android.sdk.health.data.request.DataTypes
import com.samsung.android.sdk.health.data.request.LocalTimeFilter
import com.samsung.android.sdk.health.data.request.Ordering
import java.time.LocalDateTime

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

    /** ExerciseType 읽기 권한 요청. 이미 허용이면 즉시 true. 동의 후 실제 허용 여부를 반환. */
    suspend fun requestExercisePermission(): Boolean {
        if (store.getGrantedPermissions(exercisePermissions)
                .containsAll(exercisePermissions)
        ) {
            return true
        }
        try {
            // requestPermissions는 요청한 집합을 그대로 반환하므로, 동의 결과는 다시 조회한다.
            store.requestPermissions(exercisePermissions, activity)
        } catch (e: ResolvablePlatformException) {
            // Samsung Health 업데이트/설정 등 해결 가능한 상태면 해결 화면을 띄운다.
            if (e.hasResolution) e.resolve(activity)
            return false
        }
        return store.getGrantedPermissions(exercisePermissions)
            .containsAll(exercisePermissions)
    }

    /**
     * 최근 [lookbackDays]일 내 가장 최근 POOL_SWIMMING 세션을 JSON 직렬화 가능한 Map으로 반환.
     * 없으면 null.
     *
     * SDK는 read 단계의 type 필터/limit을 제공하지 않으므로(EXERCISE 전체를 읽음)
     * 세션을 펼쳐서 클라이언트에서 필터·정렬한다.
     */
    suspend fun readLatestPoolSwimming(lookbackDays: Long = 90): Map<String, Any?>? {
        val end = LocalDateTime.now()
        val start = end.minusDays(lookbackDays)

        val request = DataTypes.EXERCISE.readDataRequestBuilder
            .setLocalTimeFilter(LocalTimeFilter.of(start, end))
            .setOrdering(Ordering.DESC)
            .build()

        val latest = store.readData(request).dataList
            .mapNotNull { it.getValue(DataType.ExerciseType.SESSIONS) }
            .flatten()
            .filter {
                it.exerciseType ==
                    DataType.ExerciseType.PredefinedExerciseType.POOL_SWIMMING &&
                    it.swimmingLog != null
            }
            .maxByOrNull { it.startTime }
            ?: return null

        return latest.toSwimmingLogMap()
    }
}
