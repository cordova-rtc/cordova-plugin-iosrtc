import Foundation

class PluginRTCRtpCodecParameters : NSObject {
	var rtcRtpCodecParameters: RTCRtpCodecParameters

	init(_ rtcRtpCodecParameters: RTCRtpCodecParameters) {
		self.rtcRtpCodecParameters = rtcRtpCodecParameters
	}

	func getJSON() -> NSDictionary {
		return [
			"kind": self.rtcRtpCodecParameters.kind,
			"name": self.rtcRtpCodecParameters.name,
			"payloadType": self.rtcRtpCodecParameters.payloadType,
			"mimeType": NSString(format: "%@/%@", self.rtcRtpCodecParameters.name, self.rtcRtpCodecParameters.kind),
			"clockRate": (self.rtcRtpCodecParameters.clockRate ?? nil) as Any,
			"channels": (self.rtcRtpCodecParameters.numChannels ?? nil) as Any,
			"sdpFmtpLine": self.rtcRtpCodecParameters.parameters
		]
	}
}
