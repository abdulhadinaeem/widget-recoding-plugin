# Changelog

All notable changes to this project will be documented in this file.

## 1.0.5 - NEW FEATURES RELEASE 🎉

### ✨ New Features

#### 📸 Screenshot Capture
- **High-Quality Screenshots** - Capture PNG/JPG screenshots with configurable resolution
- **Configurable Pixel Ratio** - Support for 1x, 2x, 3x (retina) resolution
- **Format Options** - PNG (lossless) or JPG (lossy with quality control)
- **Instant Capture** - Single method call: `captureScreenshot()`
- **Use Cases** - App store screenshots, bug reports, documentation

#### 🎞️ GIF Export
- **Animated GIF Export** - Convert widget recordings to shareable GIF files
- **Quality Presets** - Low (10 FPS, 64 colors), Medium (15 FPS, 128 colors), High (24 FPS, 256 colors)
- **Auto or Manual Control** - Timed recording with `exportAsGif()` or manual with `startGifRecording()`/`stopGifRecording()`
- **Optimized Encoding** - Color quantization for smaller file sizes
- **Proper Frame Timing** - Fixed GIF playback speed using centiseconds
- **Perfect for Documentation** - Ideal for README files, PRs, and social media

#### 👆 Touch Visualization
- **Touch Indicators** - Show touch points during recording and GIF export
- **Ripple Effects** - Animated ripple animations on tap
- **Fully Customizable** - Configure color, size, opacity, ripple duration
- **Tutorial Perfect** - Essential for app demos, tutorials, and user guides
- **Easy Toggle** - Enable/disable via `showTouches` parameter

#### 🎯 Video Quality Presets (NEW)
- **Predefined Quality Levels** - Low (15 FPS, 2 Mbps), Medium (30 FPS, 5 Mbps), High (60 FPS, 10 Mbps)
- **Easy to Use** - `controller.applyVideoQuality(VideoQuality.medium)`
- **Optimized Settings** - Balanced FPS and bitrate combinations
- **File Size Control** - Choose based on your needs

#### ⏱️ Countdown Timer (NEW)
- **3-2-1 Countdown** - Prepare before recording starts
- **Customizable Duration** - Set any countdown length
- **Callback Support** - `onTick` callback for UI updates
- **Hands-Free Recording** - Perfect for self-recording and demos
- **Two Methods** - `startWithCountdown()` or `start(countdown: ...)`

#### 📁 Custom Save Path (NEW)
- **Custom Directories** - Save files to any location
- **Organized Storage** - Keep recordings in dedicated folders
- **Works for All Formats** - Video, screenshot, and GIF
- **Directory Creation** - Automatically creates directories if needed
- **Fallback to Temp** - Uses temp directory if path not specified

### 🎯 API Additions

**WidgetRecorderController:**
- Added `showTouches` parameter (default: false)
- Added `touchConfig` parameter for touch visualization customization
- Added `customSavePath` parameter for custom save directories **NEW**
- Added `captureScreenshot()` method for instant screenshots
- Added `exportAsGif()` method for automatic timed GIF recording
- Added `startGifRecording()` method for manual GIF control
- Added `stopGifRecording()` method to finish and export GIF
- Added `applyVideoQuality()` method to set quality presets **NEW**
- Added `startWithCountdown()` method for countdown before recording **NEW**
- Enhanced `start()` method with optional countdown parameter **NEW**
- Added `isRecordingGif` getter to check GIF recording status

**New Classes:**
- `TouchVisualizationConfig` - Configure touch indicator appearance
- `ImageFormat` enum - PNG or JPG format selection
- `GifQuality` enum - Low, Medium, High quality presets
- `VideoQuality` enum - Low, Medium, High video quality presets **NEW**

### 📦 Dependencies
- Added `image` package (^4.1.7) for GIF encoding and manipulation

### 🎨 Example App Updates
- Added home screen with navigation to different demos
- Created `NewFeaturesDemo` page showcasing all three new features
- Interactive examples for screenshot, GIF, and touch visualization
- Improved UI with Material 3 design
- Better demo organization and user experience

### 📚 Documentation
- Comprehensive README update with new feature documentation
- Added API reference for all new methods and classes
- Added usage examples for each feature
- Updated output specifications table
- Added troubleshooting tips for new features

### 🧪 Testing
- Added 17 comprehensive unit and widget tests
- Tests cover all new features and configurations
- 100% pass rate on Android and iOS
- Tests include controller initialization, enums, touch visualization, and integration scenarios

### 🔧 Technical Improvements
- All features work seamlessly with existing video recording
- Touch visualization works during both video and GIF recording
- Memory-efficient frame handling for GIF export
- Proper resource cleanup and disposal
- Cross-platform compatibility (Android & iOS)

### 📱 Platform Support
- ✅ Android API 21+ - Fully supported
- ✅ iOS 13.0+ - Fully supported
- Screenshot, GIF, and touch visualization work identically on both platforms

### 💡 Use Cases

**Screenshot Capture:**
- App store screenshots with high resolution
- Bug reports with visual context
- Testing and QA documentation
- Social media content creation

**GIF Export:**
- README documentation and demos
- GitHub pull requests
- Twitter/LinkedIn feature showcases
- Tutorial content for blogs

**Touch Visualization:**
- YouTube app tutorials
- User onboarding videos
- Feature demonstrations
- Customer support materials

### ⚡ Performance
- Efficient GIF encoding with color quantization
- Minimal overhead for touch visualization
- Optimized frame capture for screenshots
- No impact on existing video recording performance

### 🔄 Backward Compatibility
- ✅ Fully backward compatible
- Existing code works without changes
- New features are opt-in
- No breaking changes

---

## 1.0.4

### 🐛 Critical Bug Fix - Android ArrayIndexOutOfBoundsException

#### Issue Resolved
- **Fixed:** `ArrayIndexOutOfBoundsException` on Android devices
- **Error:** `java.lang.ArrayIndexOutOfBoundsException: length=1332800; index=1332800`
- **Location:** `WidgetRecorderPlugin.kt:123` in `encodeRgbaToImage` function
- **Impact:** Affects all Android devices including Samsung S26, Android 16, and emulators

#### Root Cause
- Missing bounds checking when accessing RGBA byte array
- Frame data size mismatch between Dart layer and Android encoder
- Same underlying issue as iOS (fixed in 1.0.3) but manifested differently on Android

#### Solution
- Added comprehensive bounds checking in `encodeRgbaToImage` function
- Validates RGBA array size before processing
- Added bounds checks for both Y plane and UV plane conversions
- Graceful error handling with detailed logging
- Prevents crashes and provides clear error messages

#### Technical Changes

**Android Layer (WidgetRecorderPlugin.kt):**
```kotlin
// Added array size validation
val expectedSize = width * height * 4
if (rgba.size < expectedSize) {
    android.util.Log.e("WidgetRecorder", "RGBA array too small...")
    return
}

// Added bounds checking in Y plane conversion
if (i + 2 >= rgba.size) {
    android.util.Log.e("WidgetRecorder", "Index out of bounds at Y plane...")
    return
}

// Added bounds checking in UV plane conversion
if (i + 2 >= rgba.size) {
    android.util.Log.e("WidgetRecorder", "Index out of bounds at UV plane...")
    continue
}
```

#### Tested Scenarios
- ✅ Samsung S26 (Android 16)
- ✅ Android emulators
- ✅ Various widget dimensions
- ✅ Multiple recording sessions
- ✅ Different screen sizes and orientations

#### Related Issues
- Complements the iOS fix in v1.0.3
- Part of the comprehensive frame size mismatch resolution
- Works together with Dart layer fixes from v1.0.3

---

## 1.0.3

### 🐛 Critical Bug Fix - Frame Size Mismatch

#### Issue Resolved
- **Fixed:** Frame data size mismatch error causing recording failures
- **Error:** `Error: Frame data size mismatch. Expected: 3812352, Got: 3793664`
- **Impact:** Resolves orientation-specific recording issues on iOS/iPad devices

#### Root Cause
- Pixel ratio calculation was causing size mismatches between Dart and native layers
- Different orientations produced different dimension rounding
- iPad vs iPhone had inconsistent behavior

#### Solution
- Changed to 1.0 pixel ratio capture for exact dimension matching
- Added frame size validation before sending to native layer
- Added image resizing when dimensions don't match encoder expectations
- Proper image disposal to prevent memory leaks

#### Technical Changes

**Dart Layer (lib/widget_recorder.dart):**
- Changed from calculated pixel ratio to fixed 1.0 pixel ratio
- Added `_resizeImage()` method for dimension correction
- Added frame size validation with clear error messages
- Added proper image disposal to prevent memory leaks
- Added bounds checking before sending data

**Android Layer (WidgetRecorderPlugin.kt):**
- Added frame data size validation before encoding
- Enhanced error logging with detailed messages
- Better logging for input buffer availability
- Improved exception handling

**iOS Layer (WidgetRecorderPlugin.swift):**
- Frame size validation already present in 1.0.2
- Bounds checking already implemented

#### Tested Scenarios
- ✅ Portrait and landscape orientations
- ✅ iPad and iPhone devices
- ✅ Various widget dimensions
- ✅ ExtendBodyBehindAppBar configurations
- ✅ Camera preview recording
- ✅ Long recording sessions

#### Documentation
- Added TROUBLESHOOTING.md with comprehensive solutions
- Added frame size mismatch troubleshooting guide
- Added orientation-specific issue resolution
- Added best practices for dimension handling

#### Special Thanks
- Thanks to **Martijn Molder** for the detailed bug report!

---

## 1.0.2

### 🚀 Automatic Permission Handling & Camera Recording

#### New Features
- 🔐 **Automatic Permission Handling** - Zero boilerplate permission management
  - Permissions handled automatically when `recordAudio: true`
  - Built-in default permission dialog with Settings option
  - Optional custom dialog support via `permissionDeniedDialog` parameter
  - Smart permission flow: check → request → dialog → settings
  - 93% code reduction for permission handling
- 📸 **Camera Recording Example** - Complete camera recording test implementation
  - Real-world example with camera preview
  - Proper dimension handling for encoding
  - Multiple recording support without corruption
  - Clean UI with recording indicators

#### Improvements
- ✨ **Simplified API** - Just call `controller.start()`, permissions handled automatically
- 🎯 **Better Developer Experience** - No manual permission checks needed
- 📱 **Cleaner Code** - Removed permission boilerplate from examples
- 🔧 **Context Management** - Automatic context capture for permission dialogs
- 🎨 **Customizable Dialogs** - Full control over permission dialog UI

#### Bug Fixes
- ✅ Fixed camera recording frame size mismatch
- ✅ Fixed video corruption on multiple recordings
- ✅ Fixed REC indicator appearing in recorded video
- ✅ Reduced excessive logging for cleaner console output
- ✅ Fixed dimension calculation for optimal encoding

#### Documentation
- 📚 Added AUTOMATIC_PERMISSIONS.md - Complete automatic permission guide
- 📚 Added PERMISSION_FLOW.md - Visual permission flow diagrams
- 📚 Added custom_dialog_example.dart - Custom dialog implementation
- 📚 Updated README.md with automatic permission examples
- 📚 Updated API reference with new parameters

#### Example App Updates
- 🎥 Added camera recording test screen
- 🔐 Simplified permission handling (automatic)
- 📊 Removed manual permission checks
- ✨ Cleaner, more maintainable code
- 🎯 Better user experience

#### Breaking Changes
- ⚠️ **None!** Fully backward compatible
- Manual permission methods still available
- Existing code continues to work

#### Migration
```dart
// Before (Manual - 15+ lines)
if (!await controller.hasPermission()) {
  bool granted = await controller.requestPermission();
  if (!granted) {
    showDialog(...);
    return;
  }
}
await controller.start();

// After (Automatic - 1 line)
await controller.start(); // Done! 🎉
```

---

## 1.0.1

### 🎤 Audio Recording & Quality Improvements

#### New Features
- 🎤 **Audio Recording Support** - Optional microphone audio capture on iOS & Android
- 🔐 **Built-in Permission Handling** - No external packages required
  - `hasPermission()` - Check microphone permission status
  - `requestPermission()` - Request microphone access with system dialog
  - `openSettings()` - Open app settings for manual permission grant
- 🎵 **AAC Audio Encoding** - High-quality 128 kbps stereo at 44.1 kHz
- 📱 **Audio/Video Synchronization** - Proper timestamp alignment

#### Quality Improvements
- 📹 **Optimized Video Bitrate** - Improved calculation based on resolution and FPS (3-50 Mbps range)
- ✨ **Enhanced H.264 Settings** - Added quality parameters for clearer videos
  - AVVideoQualityKey: 0.85 for high quality
  - Keyframe interval optimization (every 2 seconds)
  - Better frame reordering for screen recording
  - Expected source frame rate hints
- 🎯 **Better Frame Capture** - Removed unnecessary image resizing, improved pixel ratio calculation
- 🚀 **Performance Optimized** - More efficient encoding pipeline

#### Platform Implementations

**iOS:**
- AVAudioEngine for microphone capture
- AVCaptureDevice for permission handling
- Proper audio format conversion (44.1kHz stereo)
- Audio sample buffer creation and synchronization

**Android:**
- AudioRecord API for microphone capture
- Separate audio encoding thread for performance
- ActivityAware implementation for permission handling
- Runtime permission request handling
- Settings navigation support

#### Documentation
- 📚 Added AUDIO_SETUP.md - Comprehensive audio recording guide
- 📚 Added PERMISSIONS.md - Built-in permission handling documentation
- 📚 Updated README.md with audio examples and permission handling
- 🎬 Added demo GIF to README
- 📝 Complete API reference for permission methods

#### Example App Updates
- 🎤 Enabled audio recording in example
- 🔐 Integrated permission handling UI
- 📊 Added microphone status indicator (green/red)
- ✨ Improved user experience with permission dialogs
- 🎯 Permission check on app startup

#### Bug Fixes
- ✅ Fixed video quality issues with optimized encoding parameters
- ✅ Fixed pixel ratio causing quality degradation
- ✅ Improved audio/video synchronization
- ✅ Fixed import statement in README example

---

## 1.0.0

### ✨ Initial Release

#### Features
- 🎥 Record any Flutter widget as MP4 video
- ⚡ Simple 3-line API integration
- 🎯 Configurable FPS (15-60, default 60)
- 📱 Cross-platform support (Android API 21+, iOS 13+)
- 🔧 Automatic file path management
- 💾 Built-in success and error callbacks
- 🎬 High-quality H.264 encoding

#### Android Implementation
- Uses MediaCodec for hardware-accelerated H.264 encoding
- Proper YUV420 color space conversion with 2x2 subsampling
- Handles hardware stride/padding requirements via Image API
- Synchronous file finalization with CountDownLatch
- Robust error handling and resource cleanup
- Supports devices with MediaTek, Qualcomm, and other encoders

#### iOS Implementation
- Uses AVAssetWriter for native video encoding
- H.264 codec with high profile level
- CABAC entropy mode for better compression
- Proper RGBA to BGRA conversion
- Synchronous finalization with DispatchSemaphore
- Supports iOS 13.0+

#### Dart Layer
- RepaintBoundary-based frame capture
- Automatic dimension rounding to multiples of 16 (H.264 macroblock requirement)
- Smooth frame timing and synchronization

#### Fixes
- ✅ Fixed array index out of bounds crash
- ✅ Fixed video distortion from stride mismatch
- ✅ Fixed "unsupported media" error for long videos
- ✅ Fixed incomplete file finalization
- ✅ Fixed color space conversion issues
- ✅ Fixed frame timing and synchronization

#### Documentation
- Comprehensive README with examples
- API reference documentation
- Troubleshooting guide
- Performance tips
- Platform-specific setup instructions
- App Store compliance notes

#### Example App
- Complete working example with UI
- Animation recording demo
- Error handling demonstration
- Video playback integration

---

**Version 1.0.2** - Automatic Permission Handling & Camera Recording  
**Version 1.0.1** - Audio Recording & Quality Improvements  
**Version 1.0.0** - Initial Production Release
