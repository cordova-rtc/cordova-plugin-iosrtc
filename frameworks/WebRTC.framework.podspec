Pod::Spec.new do |s|
  s.name         = "WebRTC.framework"
  s.version      = "1.0.69"
  s.summary      = "WebRTC SDK for iOS"
  s.description  = <<-DESC
    WebRTC is a free, open project that provides browsers and mobile
    applications with Real-Time Communications (RTC) capabilities via simple
    APIs.
                   DESC
  s.homepage     = "http://webrtc.org/"
  s.source       = { :git => "https://github.com/cordova-rtc/cordova-plugin-iosrtc/tree/master/lib/WebRTC.framework", :tag => s.version }
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author    = "Google Inc."

  s.platform     = :ios, "8.0"

  s.source_files = "WebRTC.framework/Headers/**/*.h"
  s.public_header_files = "WebRTC.framework/Headers/**/*.h"
  s.vendored_frameworks = "WebRTC.framework"
end