import Foundation

class PluginRTCRtpEncodingParameters : NSObject {
	var rtcRtpEncodingParameters: RTCRtpEncodingParameters
	
	init(_ rtcRtpEncodingParameters: RTCRtpEncodingParameters) {
		self.rtcRtpEncodingParameters = rtcRtpEncodingParameters
	}
		
	func getJSON() -> NSDictionary {
		return [
			"rid": self.rtcRtpEncodingParameters.rid,
			"active": self.rtcRtpEncodingParameters.isActive,
			"maxBitrate": self.rtcRtpEncodingParameters.maxBitrateBps,
			"minBitrate": self.rtcRtpEncodingParameters.minBitrateBps,
			"scaleResolutionDownBy": self.rtcRtpEncodingParameters.scaleResolutionDownBy
		]
	}
}
