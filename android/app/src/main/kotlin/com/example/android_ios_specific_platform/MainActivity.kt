package com.example.android_ios_specific_platform
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import com.yalantis.ucrop.UCrop
import com.yalantis.ucrop.UCropActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.image_editor/crop"
    private val cropRequestCode = 1001

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "cropImage" -> {
                    val bytes =
                        call.argument<ByteArray>("imageBytes")

                    if (bytes == null) {
                        result.error(
                            "INVALID_IMAGE",
                            "Image bytes missing",
                            null
                        )
                    } else {
                        startNativeCrop(bytes, result)
                    }
                }

                "flipImage" -> {
                    val bytes =
                        call.argument<ByteArray>("imageBytes")

                    val horizontal =
                        call.argument<Boolean>("horizontal") ?: true

                    if (bytes == null) {
                        result.error(
                            "INVALID_IMAGE",
                            "Image bytes missing",
                            null
                        )
                    } else {
                        transformImage(
                            bytes,
                            if (horizontal) "horizontal" else "vertical",
                            result
                        )
                    }
                }

                "rotateImage" -> {
                    val bytes =
                        call.argument<ByteArray>("imageBytes")

                    if (bytes == null) {
                        result.error(
                            "INVALID_IMAGE",
                            "Image bytes missing",
                            null
                        )
                    } else {
                        transformImage(
                            bytes,
                            "rotate",
                            result
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // INTERACTIVE NATIVE CROPPING
    private fun startNativeCrop(
        bytes: ByteArray,
        result: MethodChannel.Result
    ) {
        try {
            if (pendingResult != null) {
                result.error(
                    "BUSY",
                    "Another crop operation is running",
                    null
                )
                return
            }

            val timestamp = System.currentTimeMillis()

            val sourceFile = File(
                cacheDir,
                "source_$timestamp.jpg"
            )

            val destinationFile = File(
                cacheDir,
                "cropped_$timestamp.jpg"
            )

            sourceFile.writeBytes(bytes)

            val sourceUri = Uri.fromFile(sourceFile)
            val destinationUri = Uri.fromFile(destinationFile)

            val options = UCrop.Options().apply {

                setCompressionFormat(
                    Bitmap.CompressFormat.JPEG
                )

                setCompressionQuality(95)

                setFreeStyleCropEnabled(true)
                setShowCropGrid(true)
                setShowCropFrame(true)
                setHideBottomControls(false)

                setToolbarTitle("Native Image Editor")

                setAllowedGestures(
                    UCropActivity.SCALE,
                    UCropActivity.ROTATE,
                    UCropActivity.ALL
                )
            }

            pendingResult = result

            UCrop.of(
                sourceUri,
                destinationUri
            )
                .withOptions(options)
                .start(this, cropRequestCode)

        } catch (e: Exception) {

            pendingResult = null

            result.error(
                "CROP_ERROR",
                e.message ?: "Failed to start crop",
                null
            )
        }
    }

    // RECEIVE CROPPED IMAGE
    @Deprecated("Deprecated Android API")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (requestCode != cropRequestCode) return

        val callback = pendingResult ?: return
        pendingResult = null

        when {

            resultCode == RESULT_OK && data != null -> {
                try {
                    val outputUri = UCrop.getOutput(data)

                    if (outputUri == null) {
                        callback.error(
                            "EMPTY_RESULT",
                            "No cropped image returned",
                            null
                        )
                        return
                    }

                    val outputBytes = contentResolver
                        .openInputStream(outputUri)
                        ?.use { it.readBytes() }

                    if (outputBytes != null) {
                        callback.success(outputBytes)
                    } else {
                        callback.error(
                            "READ_ERROR",
                            "Unable to read cropped image",
                            null
                        )
                    }

                } catch (e: Exception) {
                    callback.error(
                        "CROP_ERROR",
                        e.message ?: "Failed to read cropped result",
                        null
                    )
                }
            }

            resultCode == UCrop.RESULT_ERROR -> {
                val error = data?.let {
                    UCrop.getError(it)
                }

                callback.error(
                    "CROP_ERROR",
                    error?.message ?: "Cropping failed",
                    null
                )
            }

            else -> {
                callback.success(null)
            }
        }
    }

    // NATIVE FLIP AND ROTATION
    private fun transformImage(
        bytes: ByteArray,
        operation: String,
        result: MethodChannel.Result
    ) {
        var bitmap: Bitmap? = null
        var transformed: Bitmap? = null

        try {
            bitmap = BitmapFactory.decodeByteArray(
                bytes,
                0,
                bytes.size
            ) ?: throw IllegalArgumentException(
                "Invalid image"
            )

            val matrix = Matrix().apply {
                when (operation) {
                    "horizontal" -> setScale(-1f, 1f)
                    "vertical" -> setScale(1f, -1f)
                    "rotate" -> setRotate(90f)
                    else -> throw IllegalArgumentException(
                        "Unknown operation: $operation"
                    )
                }
            }

            transformed = Bitmap.createBitmap(
                bitmap,
                0,
                0,
                bitmap.width,
                bitmap.height,
                matrix,
                true
            )

            val output = ByteArrayOutputStream()

            transformed.compress(
                Bitmap.CompressFormat.JPEG,
                95,
                output
            )

            result.success(output.toByteArray())

        } catch (e: Exception) {

            result.error(
                "TRANSFORM_ERROR",
                e.message ?: "Image transform failed",
                null
            )

        } finally {
            bitmap?.recycle()

            if (transformed !== bitmap) {
                transformed?.recycle()
            }
        }
    }
}
