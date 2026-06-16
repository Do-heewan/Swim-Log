package com.noh.swim_log

import android.util.Log
import androidx.lifecycle.lifecycleScope
import com.noh.swim_log.health.SamsungHealthBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    private val channelName = "swim_log/samsung_health"
    private val bridge by lazy { SamsungHealthBridge(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestExercisePermission" ->
                        launchOnMain(result) { bridge.requestExercisePermission() }
                    "getLatestPoolSwimming" ->
                        launchOnMain(result) { bridge.readLatestPoolSwimming() }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * suspend 브릿지 호출을 메인 스레드 코루틴(lifecycleScope)에서 실행하고
     * 결과/오류를 채널로 전달한다. result.success/error는 메인 스레드에서 호출된다.
     */
    private fun launchOnMain(
        result: MethodChannel.Result,
        block: suspend () -> Any?,
    ) {
        lifecycleScope.launch {
            try {
                result.success(block())
            } catch (e: Throwable) {
                Log.e("SwimBridge", "MethodChannel 호출 실패", e)
                result.error("SAMSUNG_HEALTH_ERROR", e.message, e.toString())
            }
        }
    }
}
