package com.example.android_ios_specific_platform
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.image_editor/crop"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "cropImage" -> {
                    try {
                        val bytes =
                            call.argument<ByteArray>("imageBytes")

                        if (bytes == null) {
                            result.error(
                                "INVALID_IMAGE",
                                "Image bytes are missing",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val bitmap = BitmapFactory.decodeByteArray(
                            bytes,
                            0,
                            bytes.size
                        )

                        if (bitmap == null) {
                            result.error(
                                "DECODE_ERROR",
                                "Unable to decode image",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        // Native center-square cropping
                        val cropSize = minOf(
                            bitmap.width,
                            bitmap.height
                        )

                        val x = (bitmap.width - cropSize) / 2
                        val y = (bitmap.height - cropSize) / 2

                        val croppedBitmap = Bitmap.createBitmap(
                            bitmap,
                            x,
                            y,
                            cropSize,
                            cropSize
                        )

                        val output = ByteArrayOutputStream()

                        croppedBitmap.compress(
                            Bitmap.CompressFormat.JPEG,
                            95,
                            output
                        )

                        result.success(output.toByteArray())

                        croppedBitmap.recycle()
                        bitmap.recycle()

                    } catch (e: Exception) {
                        result.error(
                            "CROP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
