package com.bryanschoot.snorer

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTALLER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "installApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            if (path == null) {
                result.error("INVALID_APK_PATH", "APK path is missing.", null)
                return@setMethodCallHandler
            }
            val apkFile = File(path)
            if (!apkFile.isFile) {
                result.error("APK_NOT_FOUND", "Downloaded APK was not found.", null)
                return@setMethodCallHandler
            }

            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !packageManager.canRequestPackageInstalls()
            ) {
                try {
                    startActivity(
                        Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:$packageName")
                        },
                    )
                    result.success("permission_required")
                } catch (error: ActivityNotFoundException) {
                    result.error(
                        "INSTALL_PERMISSION_UNAVAILABLE",
                        error.message,
                        null,
                    )
                }
                return@setMethodCallHandler
            }

            try {
                val apkUri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    apkFile,
                )
                startActivity(
                    Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(
                            apkUri,
                            "application/vnd.android.package-archive",
                        )
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    },
                )
                result.success("started")
            } catch (error: Exception) {
                result.error("INSTALLER_UNAVAILABLE", error.message, null)
            }
        }
    }

    companion object {
        private const val INSTALLER_CHANNEL =
            "com.bryanschoot.snorer/installer"
    }
}
