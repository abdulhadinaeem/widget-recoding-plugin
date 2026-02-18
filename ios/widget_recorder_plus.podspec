#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint widget_recorder.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'widget_recorder_plus'
  s.version          = '1.0.1'
  s.summary          = 'Record any Flutter widget as MP4 video with a simple API.'
  s.description      = <<-DESC
Record any Flutter widget as MP4 video with a simple API. Perfect for creating tutorials, demos, and exporting animated content. Supports Android (API 21+) and iOS (13+).
                       DESC
  s.homepage         = 'https://github.com/abdulhadinaeem/widget-recoding-plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Abdul Hadi Naeem' => 'abdulhadinaeem@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'widget_recorder_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
