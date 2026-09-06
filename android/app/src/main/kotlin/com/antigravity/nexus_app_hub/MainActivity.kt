package com.antigravity.nexus_app_hub

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.nexus_app_hub/app_manager"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null && packageName.isNotEmpty()) {
                        try {
                            packageManager.getPackageInfo(packageName, 0)
                            result.success(true)
                        } catch (e: PackageManager.NameNotFoundException) {
                            result.success(false)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "getAppVersion" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null && packageName.isNotEmpty()) {
                        try {
                            val pInfo = packageManager.getPackageInfo(packageName, 0)
                            result.success(pInfo.versionName ?: "")
                        } catch (e: PackageManager.NameNotFoundException) {
                            result.success(null)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null && packageName.isNotEmpty()) {
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null && packageName.isNotEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_DELETE).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNINSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null && filePath.isNotEmpty()) {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "Arquivo APK não encontrado em $filePath", null)
                            return@setMethodCallHandler
                        }

                        // Verificação de permissão para instalar fontes desconhecidas (Android 8.0+)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            if (!packageManager.canRequestPackageInstalls()) {
                                try {
                                    val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                        data = Uri.parse("package:$packageName")
                                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                    }
                                    startActivity(settingsIntent)
                                    result.error("PERMISSION_REQUIRED", "Ative a opção 'Permitir desta fonte' nas Configurações para instalar o APK.", null)
                                } catch (e: Exception) {
                                    result.error("PERMISSION_ERROR", e.message, null)
                                }
                                return@setMethodCallHandler
                            }
                        }

                        try {
                            val contentUri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(contentUri, "application/vnd.android.package-archive")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            startActivity(installIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", "Falha ao disparar instalador: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Caminho do APK não fornecido", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
