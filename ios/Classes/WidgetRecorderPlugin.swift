import Flutter
import UIKit
import AVFoundation

public class WidgetRecorderPlugin: NSObject, FlutterPlugin {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var audioEngine: AVAudioEngine?
    private var frameCount: Int64 = 0
    private var audioSampleCount: Int64 = 0
    private var fps: Int = 60
    private var width: Int = 0
    private var height: Int = 0
    private var outputPath: String?
    private var isRunning = false
    private var recordAudio = false
    private let queue = DispatchQueue(label: "widget_recorder_queue")
    private let audioQueue = DispatchQueue(label: "widget_recorder_audio_queue")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "widget_recorder_plus", binaryMessenger: registrar.messenger())
        let instance = WidgetRecorderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkPermission":
            checkMicrophonePermission(result: result)
            
        case "requestPermission":
            requestMicrophonePermission(result: result)
            
        case "openSettings":
            openAppSettings(result: result)
            
        case "startRecording":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            width = args["width"] as? Int ?? 0
            height = args["height"] as? Int ?? 0
            fps = args["fps"] as? Int ?? 60
            outputPath = args["outputPath"] as? String
            recordAudio = args["recordAudio"] as? Bool ?? false
            startEncoding()
            result(nil)
            
        case "addFrame":
            guard let args = call.arguments as? [String: Any],
                  let frameData = args["frame"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frame data", details: nil))
                return
            }
            addFrame(frameBytes: frameData.data)
            result(nil)
            
        case "stopRecording":
            stopEncodingSync()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkMicrophonePermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        result(status == .authorized)
    }
    
    private func requestMicrophonePermission(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }
    
    private func openAppSettings(result: @escaping FlutterResult) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    result(success)
                }
            } else {
                result(false)
            }
        } else {
            result(false)
        }
    }

    private func startEncoding() {
        guard let path = outputPath else { return }
        let url = URL(fileURLWithPath: path)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: url)
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
            
            // Calculate optimal bitrate based on resolution and fps
            // Formula: pixels * fps * bitsPerPixel * quality_factor
            let pixels = width * height
            let bitsPerPixel: Double = 0.15 // Balanced quality
            let qualityFactor: Double = 1.2 // Slight boost for clarity
            let bitrate = Int(Double(pixels) * Double(fps) * bitsPerPixel * qualityFactor)
            
            // Clamp bitrate to reasonable range (3-50 Mbps)
            let finalBitrate = min(max(bitrate, 3_000_000), 50_000_000)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: finalBitrate,
                    AVVideoMaxKeyFrameIntervalKey: fps * 2, 
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                    AVVideoQualityKey: 0.85,
                    AVVideoExpectedSourceFrameRateKey: fps,
                    AVVideoAllowFrameReorderingKey: false
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = false
            
            let sourcePixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput!,
                sourcePixelBufferAttributes: sourcePixelBufferAttributes
            )
            
            if assetWriter!.canAdd(videoInput!) {
                assetWriter!.add(videoInput!)
            }
            
            // Setup audio if enabled
            if recordAudio {
                setupAudioRecording()
            }
            
            assetWriter!.startWriting()
            assetWriter!.startSession(atSourceTime: CMTime.zero)
            
            isRunning = true
            frameCount = 0
            audioSampleCount = 0
            
            // Start audio engine if enabled
            if recordAudio {
                startAudioRecording()
            }
        } catch {
            print("Error starting encoding: \(error)")
        }
    }
    
    private func setupAudioRecording() {
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true
        
        if assetWriter!.canAdd(audioInput!) {
            assetWriter!.add(audioInput!)
        }
    }
    
    private func startAudioRecording() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Convert to stereo 44.1kHz format for AAC encoding
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100.0,
            channels: 2,
            interleaved: false
        )
        
        guard let outputFormat = outputFormat else { return }
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] (buffer, time) in
            guard let self = self, self.isRunning else { return }
            
            self.audioQueue.async {
                // Convert to output format if needed
                let converter = AVAudioConverter(from: recordingFormat, to: outputFormat)
                guard let converter = converter else { return }
                
                let capacity = AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(recordingFormat.sampleRate)
                guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return }
                
                var error: NSError?
                converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                if error == nil {
                    self.appendAudioBuffer(convertedBuffer)
                }
            }
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    private func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }
        
        let sampleTime = CMTimeMake(value: audioSampleCount, timescale: 44100)
        
        guard let blockBuffer = createBlockBuffer(from: buffer) else { return }
        
        var formatDescription: CMAudioFormatDescription?
        CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: buffer.format.streamDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard let formatDescription = formatDescription else { return }
        
        var sampleBuffer: CMSampleBuffer?
        CMAudioSampleBufferCreateWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: CMItemCount(buffer.frameLength),
            presentationTimeStamp: sampleTime,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        if let sampleBuffer = sampleBuffer {
            audioInput.append(sampleBuffer)
            audioSampleCount += Int64(buffer.frameLength)
        }
    }
    
    private func createBlockBuffer(from buffer: AVAudioPCMBuffer) -> CMBlockBuffer? {
        let audioBufferList = buffer.audioBufferList.pointee
        let channels = Int(audioBufferList.mNumberBuffers)
        
        guard channels > 0 else { return nil }
        
        let bufferSize = Int(audioBufferList.mBuffers.mDataByteSize) * channels
        var blockBuffer: CMBlockBuffer?
        
        let status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: bufferSize,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: bufferSize,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == kCMBlockBufferNoErr, let blockBuffer = blockBuffer else { return nil }
        
        // Copy audio data
        for i in 0..<channels {
            let audioBuffer = UnsafeBufferPointer<UInt8>(
                start: audioBufferList.mBuffers.mData?.assumingMemoryBound(to: UInt8.self),
                count: Int(audioBufferList.mBuffers.mDataByteSize)
            )
            
            CMBlockBufferReplaceDataBytes(
                with: audioBuffer.baseAddress!,
                blockBuffer: blockBuffer,
                offsetIntoDestination: i * Int(audioBufferList.mBuffers.mDataByteSize),
                dataLength: Int(audioBufferList.mBuffers.mDataByteSize)
            )
        }
        
        return blockBuffer
    }

    private func addFrame(frameBytes: Data) {
        queue.async { [weak self] in
            guard let self = self,
                  self.isRunning,
                  let pixelBufferPool = self.pixelBufferAdaptor?.pixelBufferPool else { return }
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return }
            
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            
            guard let pixelData = CVPixelBufferGetBaseAddress(buffer) else { return }
            
            // Get the actual bytes per row (stride)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            let ptr = pixelData.assumingMemoryBound(to: UInt8.self)
            
            // Copy RGBA data row by row, converting to BGRA
            var srcOffset = 0
            for row in 0..<self.height {
                let dstOffset = row * bytesPerRow
                for col in 0..<self.width {
                    let srcIdx = srcOffset + (col * 4)
                    let dstIdx = dstOffset + (col * 4)
                    
                    // RGBA to BGRA conversion
                    ptr[dstIdx] = frameBytes[srcIdx + 2]     // B
                    ptr[dstIdx + 1] = frameBytes[srcIdx + 1] // G
                    ptr[dstIdx + 2] = frameBytes[srcIdx]     // R
                    ptr[dstIdx + 3] = frameBytes[srcIdx + 3] // A
                }
                srcOffset += self.width * 4
            }
            
            let presentationTime = CMTimeMake(value: self.frameCount, timescale: Int32(self.fps))
            
            if self.videoInput?.isReadyForMoreMediaData ?? false {
                self.pixelBufferAdaptor?.append(buffer, withPresentationTime: presentationTime)
                self.frameCount += 1
            }
        }
    }

    private func stopEncodingSync() {
        let semaphore = DispatchSemaphore(value: 0)
        
        // Stop audio engine first
        if recordAudio {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine = nil
        }
        
        queue.async { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            self.isRunning = false
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()
            
            let endTime = CMTimeMake(value: self.frameCount, timescale: Int32(self.fps))
            self.assetWriter?.endSession(atSourceTime: endTime)
            
            self.assetWriter?.finishWriting {
                if let error = self.assetWriter?.error {
                    print("Error stopping encoding: \(error)")
                }
                self.assetWriter = nil
                self.videoInput = nil
                self.audioInput = nil
                self.pixelBufferAdaptor = nil
                semaphore.signal()
            }
        }
        
        // Wait for finishWriting to complete (max 30 seconds)
        let result = semaphore.wait(timeout: .now() + 30)
        if result == .timedOut {
            print("Warning: stopEncoding timed out")
        }
    }

    private func stopEncoding() {
        // Stop audio engine first
        if recordAudio {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine = nil
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isRunning = false
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()
            
            let endTime = CMTimeMake(value: self.frameCount, timescale: Int32(self.fps))
            self.assetWriter?.endSession(atSourceTime: endTime)
            
            self.assetWriter?.finishWriting {
                if let error = self.assetWriter?.error {
                    print("Error stopping encoding: \(error)")
                }
                self.assetWriter = nil
                self.videoInput = nil
                self.audioInput = nil
                self.pixelBufferAdaptor = nil
            }
        }
    }
}
