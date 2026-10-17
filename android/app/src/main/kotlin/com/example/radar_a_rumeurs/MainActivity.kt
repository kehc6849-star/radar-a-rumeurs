package com.example.radar_a_rumeurs

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

/**
 * Receives what other apps share with Zero Trust: a text, an image, or a text
 * selected in the text selection menu.
 *
 * This class only reads the Android intent and sends a simple map to Dart.
 * Dart checks the content and decides what to do with it.
 */
class MainActivity : FlutterActivity() {
    private var sharedContentChannel: MethodChannel? = null

    // The intent that started the app is given to Dart only once.
    private var isStartIntentTaken = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // After a restart by the system, the old share must not be analyzed again.
        isStartIntentTaken = savedInstanceState != null

        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                TAKE_INITIAL_CONTENT_METHOD -> takeInitialContent(result)
                else -> result.notImplemented()
            }
        }

        sharedContentChannel = channel
    }

    // The app is already open and another share arrives.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Dart did not ask for the start content yet: it will read this new intent.
        if (!isStartIntentTaken) {
            return
        }

        readSharedContentInBackground(intent) { content ->
            if (content != null) {
                sharedContentChannel?.invokeMethod(CONTENT_RECEIVED_METHOD, content)
            }
        }
    }

    private fun takeInitialContent(result: MethodChannel.Result) {
        if (isStartIntentTaken) {
            result.success(null)
            return
        }

        isStartIntentTaken = true

        readSharedContentInBackground(intent) { content ->
            result.success(content)
        }
    }

    // Reading an image can take some time, so it never runs on the main thread.
    private fun readSharedContentInBackground(
        sourceIntent: Intent?,
        onRead: (Map<String, Any?>?) -> Unit,
    ) {
        thread(name = "zero-trust-shared-content") {
            val content: Map<String, Any?>? = try {
                readSharedContent(sourceIntent)
            } catch (error: Exception) {
                buildUnreadableContent()
            } catch (error: OutOfMemoryError) {
                buildUnreadableContent()
            }

            runOnUiThread { onRead(content) }
        }
    }

    // Returns null when the intent is not a share (for example a normal launch).
    private fun readSharedContent(sourceIntent: Intent?): Map<String, Any?>? {
        if (sourceIntent == null) {
            return null
        }

        // Android replays the old intent when the app is reopened from the recent apps.
        if ((sourceIntent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) {
            return null
        }

        if (sourceIntent.action == Intent.ACTION_PROCESS_TEXT) {
            return buildTextContent(sourceIntent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT))
        }

        if (sourceIntent.action != Intent.ACTION_SEND) {
            return null
        }

        val mimeType: String = sourceIntent.type ?: ""

        if (mimeType.startsWith("image/")) {
            return buildImageContent(readStreamUri(sourceIntent))
        }

        if (mimeType.startsWith("text/")) {
            return buildTextContent(sourceIntent.getCharSequenceExtra(Intent.EXTRA_TEXT))
        }

        return buildUnreadableContent()
    }

    @Suppress("DEPRECATION")
    private fun readStreamUri(sourceIntent: Intent): Uri? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return sourceIntent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        }

        return sourceIntent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
    }

    private fun buildTextContent(text: CharSequence?): Map<String, Any?> {
        // An empty text is sent as is: Dart shows a clear message to the user.
        return mapOf("type" to TYPE_TEXT, "text" to (text?.toString() ?: ""))
    }

    private fun buildImageContent(imageUri: Uri?): Map<String, Any?> {
        if (imageUri == null) {
            return buildUnreadableContent()
        }

        val imageBytes: ByteArray = shrinkImage(imageUri) ?: return buildUnreadableContent()

        return mapOf("type" to TYPE_IMAGE, "bytes" to imageBytes)
    }

    private fun buildUnreadableContent(): Map<String, Any?> {
        return mapOf("type" to TYPE_UNREADABLE)
    }

    // Same rule as the gallery picker: smaller images are faster to send and use
    // less of the AI quota. The result is always a JPEG.
    private fun shrinkImage(imageUri: Uri): ByteArray? {
        val boundsOptions = BitmapFactory.Options()
        boundsOptions.inJustDecodeBounds = true

        contentResolver.openInputStream(imageUri)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, boundsOptions)
        }

        if (boundsOptions.outWidth <= 0 || boundsOptions.outHeight <= 0) {
            return null
        }

        val decodeOptions = BitmapFactory.Options()
        decodeOptions.inSampleSize =
            computeSampleSize(boundsOptions.outWidth, boundsOptions.outHeight)

        val decodedBitmap: Bitmap = contentResolver.openInputStream(imageUri)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, decodeOptions)
        } ?: return null

        val scaledBitmap = scaleToMaximumSide(decodedBitmap)
        val flatBitmap = flattenOnWhite(scaledBitmap)

        val output = ByteArrayOutputStream()
        val isCompressed = flatBitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, output)

        return if (isCompressed) output.toByteArray() else null
    }

    // Reads a smaller picture directly, so a large photo does not fill the memory.
    private fun computeSampleSize(width: Int, height: Int): Int {
        val longestSide = maxOf(width, height)
        var sampleSize = 1

        while (longestSide / (sampleSize * 2) >= MAXIMUM_IMAGE_SIDE) {
            sampleSize *= 2
        }

        return sampleSize
    }

    private fun scaleToMaximumSide(bitmap: Bitmap): Bitmap {
        val longestSide = maxOf(bitmap.width, bitmap.height)

        if (longestSide <= MAXIMUM_IMAGE_SIDE) {
            return bitmap
        }

        val ratio = MAXIMUM_IMAGE_SIDE.toFloat() / longestSide
        val newWidth = maxOf(1, (bitmap.width * ratio).toInt())
        val newHeight = maxOf(1, (bitmap.height * ratio).toInt())

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    // A JPEG has no transparency: transparent pixels would become black.
    private fun flattenOnWhite(bitmap: Bitmap): Bitmap {
        if (!bitmap.hasAlpha()) {
            return bitmap
        }

        val flatBitmap = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(flatBitmap)

        canvas.drawColor(Color.WHITE)
        canvas.drawBitmap(bitmap, 0f, 0f, null)

        return flatBitmap
    }

    private companion object {
        // Must be the same names as in android_shared_content_receiver.dart.
        const val CHANNEL_NAME = "zero_trust/shared_content"
        const val TAKE_INITIAL_CONTENT_METHOD = "takeInitialContent"
        const val CONTENT_RECEIVED_METHOD = "contentReceived"

        const val TYPE_TEXT = "text"
        const val TYPE_IMAGE = "image"
        const val TYPE_UNREADABLE = "unreadable"

        const val MAXIMUM_IMAGE_SIDE = 1600
        const val JPEG_QUALITY = 85
    }
}
