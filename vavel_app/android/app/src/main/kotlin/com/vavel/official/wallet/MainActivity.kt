package com.vavel.official.wallet

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult as GmsResult
import com.google.android.gms.common.GoogleApiAvailability
import com.huawei.hms.api.ConnectionResult as HmsResult
import com.huawei.hms.api.HuaweiApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.vavel.official.wallet/secure_window",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val secure = call.arguments as? Boolean ?: false
                    runOnUiThread {
                        if (secure) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.vavel.official.wallet/push",
        ).setMethodCallHandler { call, r ->
            when (call.method) {
                "getProvider" -> r.success(resolvePushProvider())
                "requestPostNotifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                            != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(
                                this@MainActivity,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                REQ_POST_NOTIF,
                            )
                        }
                    }
                    r.success(true)
                }
                else -> r.notImplemented()
            }
        }
    }

    private fun resolvePushProvider(): String {
        val hms = HuaweiApiAvailability.getInstance()
        if (hms.isHuaweiMobileServicesAvailable(this) == HmsResult.SUCCESS) {
            return "hms"
        }
        val gms = GoogleApiAvailability.getInstance()
        return if (gms.isGooglePlayServicesAvailable(this) == GmsResult.SUCCESS) {
            "fcm"
        } else {
            "none"
        }
    }

    private companion object {
        private const val REQ_POST_NOTIF: Int = 0x4E21
    }
}
