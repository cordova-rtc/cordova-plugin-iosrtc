import Foundation

class PluginRTCRtpSender : NSObject {
	var rtpSender: RTCRtpSender
	var id: Int

	init(_ rtpSender: RTCRtpSender, _ id: Int) {
		self.rtpSender = rtpSender
		self.id = id != 0 ? id : Int.random(in: 0...10000)
	}

	func setParameters(_ params: [String : NSObject],
		_ callback: @escaping (_ data: NSDictionary) -> Void,
		_ errback: @escaping (_ error: Error) -> Void
	) {
		let oldParameters : RTCRtpParameters! = rtpSender.parameters
		let newParameters : RTCRtpParameters! = RTCRtpParameters()
		newParameters.transactionId = oldParameters.transactionId

		let encodings = params["encodings"] as? [[String:Any]]
		if encodings != nil {
			for e in encodings! {
				let p : RTCRtpEncodingParameters = RTCRtpEncodingParameters()
				if e["maxBitrate"] as? NSNumber != nil {
					p.maxBitrateBps = e["maxBitrate"] as? NSNumber
				}
				if e["scaleResolutionDownBy"] as? NSNumber != nil {
					p.scaleResolutionDownBy = e["scaleResolutionDownBy"] as? NSNumber
				}
				newParameters.encodings.append(p)
			}
		}

		rtpSender.parameters = newParameters

		var newCodecs : [NSDictionary] = []
		for c in newParameters.codecs {
			let codec = PluginRTCRtpCodecParameters(c)
			newCodecs.append(codec.getJSON())
		}

		var newEncodings : [NSDictionary] = []
		for e in newParameters.encodings {
			let encoding = PluginRTCRtpEncodingParameters(e)
			newEncodings.append(encoding.getJSON())
		}

		let newHeaderExtensions : [NSDictionary] = []

		let result : [String : Any] = [
			"codecs": newCodecs,
			"encodings": newEncodings,
			"headerExtensions": newHeaderExtensions
		]
		callback(result as NSDictionary)
	}
	
	func replaceTrack(_ pluginMediaStreamTrack: PluginMediaStreamTrack?) {
		let rtcMediaStreamTrack = pluginMediaStreamTrack?.rtcMediaStreamTrack
		self.rtpSender.track = rtcMediaStreamTrack
	}

	func getJSON() -> NSDictionary {
		let track = self.rtpSender.track != nil ? [
			"id": self.rtpSender.track!.trackId,
			   "kind": self.rtpSender.track!.kind,
			   "readyState": self.rtpSender.track!.readyState == RTCMediaStreamTrackState.live ? "live" : "ended",
			   "enabled": self.rtpSender.track!.isEnabled,
			   "label": self.rtpSender.track!.trackId
		] : nil
		return [
			"id": self.id,
			"senderId": self.rtpSender.senderId,
			"params": PluginRTCRtpParameters(self.rtpSender.parameters).getJSON(),
			"track": track
		]
	}
}
