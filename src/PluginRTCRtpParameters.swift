import Foundation

class PluginRTCRtpParameters : NSObject {
	var rtcRtpParameters: RTCRtpParameters

	init(_ rtcRtpParameters: RTCRtpParameters) {
		self.rtcRtpParameters = rtcRtpParameters
	}

	func getJSON() -> NSDictionary {
		let codecs = self.rtcRtpParameters.codecs.map { (codecParams: RTCRtpCodecParameters) -> NSDictionary in
			return PluginRTCRtpCodecParameters(codecParams).getJSON()
		}
		let encodings = self.rtcRtpParameters.encodings.map { (encodingParams: RTCRtpEncodingParameters) -> NSDictionary in
			return PluginRTCRtpEncodingParameters(encodingParams).getJSON()
		}
		return [
			"codecs": codecs,
			"encodings": encodings
		]
	}
}
