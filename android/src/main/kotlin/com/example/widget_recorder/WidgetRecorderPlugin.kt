package com.example.widget_recorder

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.Image
import android.media.AudioRecord
import android.media.AudioFormat
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import java.nio.ByteBuffer

class WidgetRecorderPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    
    private var videoEncoder: MediaCodec? = null
    private var audioEncoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var videoTrackIndex = -1
    private var audioTrackIndex = -1
    private var isRunning = false
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private var audioThread: Thread? = null
    private var frameCount: Long = 0
    private var fps: Int = 30
    private var width: Int = 0
    private var height: Int = 0
    private var outputPath: String? = null
    private var muxerStarted = false
    private var recordAudio = false
    private var audioRecord: AudioRecord? = null
    private val SAMPLE_RATE = 44100
    private val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_STEREO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    
    companion object {
        private const val PERMISSION_REQUEST_CODE = 8472
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "widget_recorder_plus")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> {
                result.success(checkPermission())
            }
            "requestPermission" -> {
                requestPermission(result)
            }
            "openSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "startRecording" -> {
                width = call.argument<Int>("width") ?: 0
                height = call.argument<Int>("height") ?: 0
                fps = call.argument<Int>("fps") ?: 30
                outputPath = call.argument<String>("outputPath")
                recordAudio = call.argument<Boolean>("recordAudio") ?: false
                startEncoding()
                result.success(null)
            }
            "addFrame" -> {
                val frameBytes = call.argument<ByteArray>("frame")
                if (frameBytes != null) addFrame(frameBytes)
                result.success(null)
            }
            "stopRecording" -> {
                stopEncodingSync()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
    
    private fun checkPermission(): Boolean {
        val ctx = context ?: return false
        return ContextCompat.checkSelfPermission(
            ctx,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestPermission(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.success(false)
            return
        }
        
        if (checkPermission()) {
            result.success(true)
            return
        }
        
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            PERMISSION_REQUEST_CODE
        )
    }
    
    private fun openAppSettings() {
        val ctx = context ?: return
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", ctx.packageName, null)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        ctx.startActivity(intent)
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            return true
        }
        return false
    }
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }
    
    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun startEncoding() {
        handlerThread = HandlerThread("EncoderThread").apply { start() }
        handler = Handler(handlerThread!!.looper)
        
        // Calculate optimal bitrate based on resolution and fps
        val pixels = width * height
        val bitsPerPixel = 0.15
        val qualityFactor = 1.2
        val bitrate = (pixels * fps * bitsPerPixel * qualityFactor).toInt().coerceIn(3_000_000, 50_000_000)
        
        val videoFormat = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
            setInteger(MediaFormat.KEY_BITRATE_MODE, MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
        }
        
        videoEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC).apply {
            configure(videoFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }

        muxer = MediaMuxer(outputPath!!, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        
        // Setup audio if enabled
        if (recordAudio) {
            setupAudioRecording()
        }
        
        isRunning = true
        frameCount = 0
        muxerStarted = false
    }
    
    private fun setupAudioRecording() {
        val audioFormat = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, SAMPLE_RATE, 2).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 128000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
        }
        
        audioEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).apply {
            configure(audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }
        
        val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT,
            bufferSize * 2
        )
        
        audioRecord?.startRecording()
        
        // Start audio recording thread
        audioThread = Thread {
            recordAudioData()
        }.apply { start() }
    }
    
    private fun recordAudioData() {
        val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        val audioData = ByteArray(bufferSize)
        var presentationTimeUs = 0L
        
        while (isRunning) {
            val read = audioRecord?.read(audioData, 0, audioData.size) ?: 0
            if (read > 0) {
                encodeAudioData(audioData, read, presentationTimeUs)
                presentationTimeUs += (read.toLong() * 1_000_000L) / (SAMPLE_RATE * 2 * 2) // stereo 16-bit
            }
        }
    }
    
    private fun encodeAudioData(audioData: ByteArray, size: Int, presentationTimeUs: Long) {
        val encoder = audioEncoder ?: return
        
        try {
            val inputBufferIndex = encoder.dequeueInputBuffer(5000)
            if (inputBufferIndex >= 0) {
                val inputBuffer = encoder.getInputBuffer(inputBufferIndex)
                inputBuffer?.clear()
                inputBuffer?.put(audioData, 0, size)
                encoder.queueInputBuffer(inputBufferIndex, 0, size, presentationTimeUs, 0)
            }
            
            drainEncoder(encoder, false, true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun addFrame(rgba: ByteArray) {
        if (!isRunning) return
        handler?.post {
            val currentEncoder = videoEncoder ?: return@post
            try {
                val index = currentEncoder.dequeueInputBuffer(5000)
                if (index >= 0) {
                    val image = currentEncoder.getInputImage(index)
                    if (image != null) {
                        encodeRgbaToImage(image, rgba)
                        val presentationTimeUs = (frameCount * 1_000_000L) / fps
                        currentEncoder.queueInputBuffer(index, 0, (width * height * 1.5).toInt(), presentationTimeUs, 0)
                        frameCount++
                    }
                }
                drainEncoder(currentEncoder, false, false)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun encodeRgbaToImage(image: Image, rgba: ByteArray) {
        val planes = image.planes
        val yBuffer = planes[0].buffer
        val uBuffer = planes[1].buffer
        val vBuffer = planes[2].buffer
        val yStride = planes[0].rowStride
        val uvStride = planes[1].rowStride
        val uvPixelStride = planes[1].pixelStride

        // First pass: write Y plane
        for (y in 0 until height) {
            for (x in 0 until width) {
                val i = (y * width + x) * 4
                val r = rgba[i].toInt() and 0xFF
                val g = rgba[i + 1].toInt() and 0xFF
                val b = rgba[i + 2].toInt() and 0xFF

                // BT.601 Y calculation
                val yVal = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yBuffer.put(y * yStride + x, yVal.coerceIn(0, 255).toByte())
            }
        }

        // Second pass: write UV plane (2x2 subsampling with proper averaging)
        for (y in 0 until height step 2) {
            for (x in 0 until width step 2) {
                var rSum = 0
                var gSum = 0
                var bSum = 0
                var count = 0

                // Average 2x2 block
                for (dy in 0..1) {
                    for (dx in 0..1) {
                        val py = y + dy
                        val px = x + dx
                        if (py < height && px < width) {
                            val i = (py * width + px) * 4
                            rSum += rgba[i].toInt() and 0xFF
                            gSum += rgba[i + 1].toInt() and 0xFF
                            bSum += rgba[i + 2].toInt() and 0xFF
                            count++
                        }
                    }
                }

                if (count > 0) {
                    val rAvg = rSum / count
                    val gAvg = gSum / count
                    val bAvg = bSum / count

                    // BT.601 U and V calculation
                    val uVal = ((-38 * rAvg - 74 * gAvg + 112 * bAvg + 128) shr 8) + 128
                    val vVal = ((112 * rAvg - 94 * gAvg - 18 * bAvg + 128) shr 8) + 128

                    val uvIndex = (y / 2) * uvStride + (x / 2) * uvPixelStride
                    uBuffer.put(uvIndex, uVal.coerceIn(0, 255).toByte())
                    vBuffer.put(uvIndex, vVal.coerceIn(0, 255).toByte())
                }
            }
        }
    }

    private fun drainEncoder(encoder: MediaCodec, endOfStream: Boolean, isAudio: Boolean) {
        val bufferInfo = MediaCodec.BufferInfo()
        var loopCount = 0
        val maxLoops = if (endOfStream) 100 else 1
        
        while (loopCount < maxLoops) {
            loopCount++
            val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, 10000)
            
            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val trackIndex = muxer!!.addTrack(encoder.outputFormat)
                    if (isAudio) {
                        audioTrackIndex = trackIndex
                    } else {
                        videoTrackIndex = trackIndex
                    }
                    
                    // Start muxer when both tracks are added (or just video if no audio)
                    if (!muxerStarted && videoTrackIndex >= 0 && (!recordAudio || audioTrackIndex >= 0)) {
                        muxer!!.start()
                        muxerStarted = true
                    }
                }
                outputBufferIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)!!
                    
                    if (muxerStarted && bufferInfo.size > 0) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        val trackIdx = if (isAudio) audioTrackIndex else videoTrackIndex
                        if (trackIdx >= 0) {
                            muxer!!.writeSampleData(trackIdx, outputBuffer, bufferInfo)
                        }
                    }
                    
                    encoder.releaseOutputBuffer(outputBufferIndex, false)
                    
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }
                }
            }
        }
    }

    private fun stopEncodingSync() {
        isRunning = false
        
        // Stop audio recording
        if (recordAudio) {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            audioThread?.join(5000)
            audioThread = null
        }
        
        // Wait for handler to process stop
        val stopLatch = java.util.concurrent.CountDownLatch(1)
        handler?.post {
            try {
                // Signal end of stream for video
                val videoIndex = videoEncoder?.dequeueInputBuffer(10000) ?: -1
                if (videoIndex >= 0) {
                    videoEncoder!!.queueInputBuffer(videoIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                }
                
                // Signal end of stream for audio
                if (recordAudio) {
                    val audioIndex = audioEncoder?.dequeueInputBuffer(10000) ?: -1
                    if (audioIndex >= 0) {
                        audioEncoder!!.queueInputBuffer(audioIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    }
                }
                
                // Drain encoders
                videoEncoder?.let { drainEncoder(it, true, false) }
                audioEncoder?.let { drainEncoder(it, true, true) }
                
                // Stop and release encoders
                videoEncoder?.stop()
                videoEncoder?.release()
                videoEncoder = null
                
                audioEncoder?.stop()
                audioEncoder?.release()
                audioEncoder = null
                
                // Stop and release muxer
                if (muxerStarted) {
                    try {
                        muxer?.stop()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                
                try {
                    muxer?.release()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                muxer = null
                
                // Clean up handler thread
                handlerThread?.quitSafely()
                handlerThread = null
                handler = null
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                stopLatch.countDown()
            }
        }
        
        // Wait for stop to complete (max 10 seconds)
        try {
            stopLatch.await(10, java.util.concurrent.TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }

    private fun stopEncoding() {
        isRunning = false
        
        // Stop audio recording
        if (recordAudio) {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            audioThread?.join(5000)
            audioThread = null
        }
        
        handler?.post {
            try {
                // Signal end of stream for video
                val videoIndex = videoEncoder?.dequeueInputBuffer(10000) ?: -1
                if (videoIndex >= 0) {
                    videoEncoder!!.queueInputBuffer(videoIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                }
                
                // Signal end of stream for audio
                if (recordAudio) {
                    val audioIndex = audioEncoder?.dequeueInputBuffer(10000) ?: -1
                    if (audioIndex >= 0) {
                        audioEncoder!!.queueInputBuffer(audioIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    }
                }
                
                // Drain encoders
                videoEncoder?.let { drainEncoder(it, true, false) }
                audioEncoder?.let { drainEncoder(it, true, true) }
                
                // Stop and release encoders
                videoEncoder?.stop()
                videoEncoder?.release()
                videoEncoder = null
                
                audioEncoder?.stop()
                audioEncoder?.release()
                audioEncoder = null
                
                // Stop and release muxer
                if (muxerStarted) {
                    try {
                        muxer?.stop()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                
                try {
                    muxer?.release()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                muxer = null
                
                // Clean up handler thread
                handlerThread?.quitSafely()
                handlerThread?.join(5000)
                handlerThread = null
                handler = null
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
