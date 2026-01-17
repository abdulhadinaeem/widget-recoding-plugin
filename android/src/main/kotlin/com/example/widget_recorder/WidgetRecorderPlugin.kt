package com.example.widget_recorder

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.Image
import android.os.Handler
import android.os.HandlerThread
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class WidgetRecorderPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var trackIndex = -1
    private var isRunning = false
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private var frameCount: Long = 0
    private var fps: Int = 30
    private var width: Int = 0
    private var height: Int = 0
    private var outputPath: String? = null
    private var muxerStarted = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "widget_recorder_plus")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> {
                width = call.argument<Int>("width") ?: 0
                height = call.argument<Int>("height") ?: 0
                fps = call.argument<Int>("fps") ?: 30
                outputPath = call.argument<String>("outputPath")
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

    private fun startEncoding() {
        handlerThread = HandlerThread("EncoderThread").apply { start() }
        handler = Handler(handlerThread!!.looper)
        
        // Calculate high-quality bitrate: 10 Mbps per megapixel
        val megapixels = (width * height) / 1_000_000.0
        val bitrate = (10_000_000 * megapixels).toInt().coerceAtLeast(5_000_000)
        
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            // Using YUV420Flexible allows us to use the Image API to handle stride
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            // High quality settings
            setInteger(MediaFormat.KEY_BITRATE_MODE, MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
            setInteger("bitrate-mode", 1) // VBR mode for better quality
        }
        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }

        muxer = MediaMuxer(outputPath!!, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        isRunning = true
        frameCount = 0
        muxerStarted = false
    }

    private fun addFrame(rgba: ByteArray) {
        if (!isRunning) return
        handler?.post {
            val currentEncoder = encoder ?: return@post
            try {
                val index = currentEncoder.dequeueInputBuffer(5000)
                if (index >= 0) {
                    // This is the key: Accessing the Image object gives us the rowStride
                    val image = currentEncoder.getInputImage(index)
                    if (image != null) {
                        encodeRgbaToImage(image, rgba)
                        val presentationTimeUs = (frameCount * 1_000_000L) / fps
                        currentEncoder.queueInputBuffer(index, 0, (width * height * 1.5).toInt(), presentationTimeUs, 0)
                        frameCount++
                    }
                }
                drainEncoder(false)
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

    private fun drainEncoder(endOfStream: Boolean) {
        val bufferInfo = MediaCodec.BufferInfo()
        var loopCount = 0
        val maxLoops = if (endOfStream) 100 else 1
        
        while (loopCount < maxLoops) {
            loopCount++
            val outputBufferIndex = encoder?.dequeueOutputBuffer(bufferInfo, 10000) ?: break
            
            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        trackIndex = muxer!!.addTrack(encoder!!.outputFormat)
                        muxer!!.start()
                        muxerStarted = true
                    }
                }
                outputBufferIndex >= 0 -> {
                    val outputBuffer = encoder!!.getOutputBuffer(outputBufferIndex)!!
                    
                    // Only write if muxer is started and we have data
                    if (muxerStarted && bufferInfo.size > 0) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer!!.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                    }
                    
                    encoder!!.releaseOutputBuffer(outputBufferIndex, false)
                    
                    // Check for end of stream
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }
                }
            }
        }
    }

    private fun stopEncodingSync() {
        isRunning = false
        
        // Wait for handler to process stop
        val stopLatch = java.util.concurrent.CountDownLatch(1)
        handler?.post {
            try {
                // Signal end of stream
                val index = encoder?.dequeueInputBuffer(10000) ?: -1
                if (index >= 0) {
                    encoder!!.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                }
                
                // Drain all remaining output buffers
                drainEncoder(true)
                
                // Stop and release encoder
                encoder?.stop()
                encoder?.release()
                encoder = null
                
                // Properly stop and release muxer
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
        handler?.post {
            try {
                // Signal end of stream
                val index = encoder?.dequeueInputBuffer(10000) ?: -1
                if (index >= 0) {
                    encoder!!.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                }
                
                // Drain all remaining output buffers
                drainEncoder(true)
                
                // Stop and release encoder
                encoder?.stop()
                encoder?.release()
                encoder = null
                
                // Properly stop and release muxer
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
                handlerThread?.join(5000) // Wait up to 5 seconds for thread to finish
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
