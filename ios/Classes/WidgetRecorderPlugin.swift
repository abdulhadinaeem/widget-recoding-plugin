import Flutter
import UIKit
import AVFoundation

public class WidgetRecorderPlugin: NSObject, FlutterPlugin {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var frameCount: Int64 = 0
    private var fps: Int = 60
    private var width: Int = 0
    private var height: Int = 0
    private var outputPath: String?
    private var isRunning = false
    private let queue = DispatchQueue(label: "widget_recorder_queue")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "widget_recorder_plus", binaryMessenger: registrar.messenger())
        let instance = WidgetRecorderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            width = args["width"] as? Int ?? 0
            height = args["height"] as? Int ?? 0
            fps = args["fps"] as? Int ?? 60
            outputPath = args["outputPath"] as? String
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

    private func startEncoding() {
        guard let path = outputPath else { return }
        let url = URL(fileURLWithPath: path)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: url)
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
            
            // Calculate high-quality bitrate: 10 Mbps per megapixel
            let megapixels = Double(width * height) / 1_000_000.0
            let bitrate = max(Int(10_000_000 * megapixels), 5_000_000)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitrate,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC
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
            
            assetWriter!.startWriting()
            assetWriter!.startSession(atSourceTime: CMTime.zero)
            
            isRunning = true
            frameCount = 0
        } catch {
            print("Error starting encoding: \(error)")
        }
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
        
        queue.async { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            self.isRunning = false
            self.videoInput?.markAsFinished()
            
            let endTime = CMTimeMake(value: self.frameCount, timescale: Int32(self.fps))
            self.assetWriter?.endSession(atSourceTime: endTime)
            
            self.assetWriter?.finishWriting {
                if let error = self.assetWriter?.error {
                    print("Error stopping encoding: \(error)")
                }
                self.assetWriter = nil
                self.videoInput = nil
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
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isRunning = false
            self.videoInput?.markAsFinished()
            
            let endTime = CMTimeMake(value: self.frameCount, timescale: Int32(self.fps))
            self.assetWriter?.endSession(atSourceTime: endTime)
            
            self.assetWriter?.finishWriting {
                if let error = self.assetWriter?.error {
                    print("Error stopping encoding: \(error)")
                }
                self.assetWriter = nil
                self.videoInput = nil
                self.pixelBufferAdaptor = nil
            }
        }
    }
}
