# Changelog

All notable changes to this project will be documented in this file.

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

**Version 1.0.1** - Audio Recording & Quality Improvements  
**Version 1.0.0** - Initial Production Release
