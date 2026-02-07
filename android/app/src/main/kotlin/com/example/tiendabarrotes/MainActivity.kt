package com.example.tiendabarrotes

import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.tiendabarrotes/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImageToGallery" -> {
                        val bytes = call.argument<ByteArray>("imageBytes")
                        val quality = call.argument<Int>("quality") ?: 100
                        val name = call.argument<String>("name")
                        if (bytes == null || bytes.isEmpty()) {
                            result.success(makeResult(false, null, "imageBytes vacío"))
                            return@setMethodCallHandler
                        }
                        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        if (bmp == null) {
                            result.success(makeResult(false, null, "No se pudo decodificar la imagen"))
                            return@setMethodCallHandler
                        }
                        result.success(saveToGallery(bmp, quality, name))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToGallery(bmp: Bitmap, quality: Int, name: String?): HashMap<String, Any?> {
        val fileName = name ?: System.currentTimeMillis().toString()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ — MediaStore con IS_PENDING
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, "$fileName.jpg")
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values
                ) ?: return makeResult(false, null, "No se pudo crear entrada en MediaStore")

                contentResolver.openOutputStream(uri)?.use { os ->
                    bmp.compress(Bitmap.CompressFormat.JPEG, quality, os)
                    os.flush()
                }

                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)

                bmp.recycle()
                return makeResult(true, uri.toString(), null)
            } else {
                // Android 9 y menor — archivo directo + media scan
                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                if (!dir.exists()) dir.mkdirs()
                val file = File(dir, "$fileName.jpg")
                file.outputStream().use { os ->
                    bmp.compress(Bitmap.CompressFormat.JPEG, quality, os)
                    os.flush()
                }
                bmp.recycle()
                MediaScannerConnection.scanFile(
                    this, arrayOf(file.absolutePath), arrayOf("image/jpeg"), null
                )
                return makeResult(true, Uri.fromFile(file).toString(), null)
            }
        } catch (e: Exception) {
            bmp.recycle()
            return makeResult(false, null, e.toString())
        }
    }

    private fun makeResult(ok: Boolean, path: String?, error: String?): HashMap<String, Any?> {
        return hashMapOf(
            "isSuccess" to ok,
            "filePath" to path,
            "errorMessage" to error
        )
    }
}
