//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Cordova/CDVPlugin.h>

@import WebRTC;
#import <WebRTC/RTCEAGLVideoView.h>

// Expose RTCEAGLVideoViewDelegate to Swift
RTC_OBJC_EXPORT
@protocol RTCEAGLVideoViewDelegate <RTCVideoViewDelegate>
@end
