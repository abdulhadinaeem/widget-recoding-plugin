import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_file/open_file.dart';

class CameraRecordingTest extends StatefulWidget {
  const CameraRecordingTest({super.key});

  @override
  State<CameraRecordingTest> createState() => _CameraRecordingTestState();
}

class _CameraRecordingTestState extends State<CameraRecordingTest> {
  late WidgetRecorderController recorderController;
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isRecording = false;
  bool isCameraInitialized = false;
  String? videoPath;
  bool isProcessing = false;
  final GlobalKey _cameraKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initController();
    initCamera();
  }
  
  void initController() {
    recorderController = WidgetRecorderController(
      recordAudio: true,
      onComplete: (path) {
        if (mounted) {
          setState(() {
            videoPath = path;
            isRecording = false;
            isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Video saved: $path'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(path),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isRecording = false;
            isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $error')),
          );
        }
      },
    );
  }

  Future<void> initCamera() async {
    debugPrint('[CameraTest] 📷 Initializing camera...');
    try {
      cameras = await availableCameras();
      
      if (cameras != null && cameras!.isNotEmpty) {
        // Use front camera (index 1) if available, otherwise use back camera
        final cameraIndex = cameras!.length > 1 ? 1 : 0;
        
        cameraController = CameraController(
          cameras![cameraIndex],
          ResolutionPreset.medium,
          enableAudio: false, // We're recording audio through widget_recorder
        );
        
        await cameraController!.initialize();
        debugPrint('[CameraTest] ✅ Camera ready (${cameraController!.value.previewSize})');
        
        if (mounted) {
          setState(() {
            isCameraInitialized = true;
          });
          
          // Auto-start recording when camera is ready
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted && !isRecording) {
            startRecording();
          }
        }
      }
    } catch (e) {
      debugPrint('[CameraTest] ❌ Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> startRecording() async {
    if (!isCameraInitialized || isRecording || isProcessing) return;
    
    try {
      setState(() => isRecording = true);
      await recorderController.start();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        setState(() => isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording || isProcessing) return;
    
    try {
      setState(() => isProcessing = true);
      await recorderController.stop();
      
      // Reset controller for next recording
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        recorderController.dispose();
        initController();
      }
      // isRecording will be set to false in onComplete callback
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        setState(() {
          isRecording = false;
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate dimensions that are multiples of 16 for optimal encoding
    final targetWidth = (screenSize.width.toInt() ~/ 16) * 16;
    final targetHeight = (screenSize.height.toInt() ~/ 16) * 16;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera widget wrapped in WidgetRecorder - ONLY CAMERA GETS RECORDED
          if (isCameraInitialized && cameraController != null)
            Center(
              child: WidgetRecorder(
                controller: recorderController,
                child: RepaintBoundary(
                  key: _cameraKey,
                  child: SizedBox(
                    width: targetWidth.toDouble(),
                    height: targetHeight.toDouble(),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox(
                            width: targetWidth.toDouble(),
                            height: targetWidth.toDouble() / cameraController!.value.aspectRatio,
                            child: CameraPreview(cameraController!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Recording indicator (OUTSIDE WidgetRecorder - won't be in video)
          if (isCameraInitialized && isRecording && !isProcessing)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Back button (OUTSIDE recording - won't be captured)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (isRecording) {
                        await stopRecording();
                        await Future.delayed(const Duration(milliseconds: 500));
                      }
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
          
          // Processing indicator
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing video...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // Dummy red button at bottom (OUTSIDE WidgetRecorder - won't be captured)
          if (!isProcessing)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    if (isRecording) {
                      await stopRecording();
                    } else {
                      await startRecording();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circle with progress
                      if (isRecording)
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.red),
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                        ),

                      // Main button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(
                                  isRecording ? 4 : 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Status text (OUTSIDE recording)
          if (!isProcessing)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRecording
                        ? '🎥 Recording... (Tap red button to stop)'
                        : '📹 Ready to record',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
