package com.jarvis.jarvis

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "jarvis/torch"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "setTorch") {
                    val on = call.argument<Boolean>("on") ?: false
                    try {
                        val cameraManager =
                            getSystemService(Context.CAMERA_SERVICE) as CameraManager
                        val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                            cameraManager.getCameraCharacteristics(id)
                                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                        }
                        if (cameraId == null) {
                            result.error("TORCH_UNAVAILABLE", "El feneri yok", null)
                        } else {
                            cameraManager.setTorchMode(cameraId, on)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("TORCH_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
