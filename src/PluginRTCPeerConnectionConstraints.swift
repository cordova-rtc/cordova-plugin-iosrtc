import Foundation


class PluginRTCPeerConnectionConstraints {
	private var constraints: RTCMediaConstraints


	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")

		if pcConstraints == nil {
			self.constraints = RTCMediaConstraints()
			return
		}

		var	offerToReceiveAudio = pcConstraints?.objectForKey("offerToReceiveAudio") as? Bool
		var	offerToReceiveVideo = pcConstraints?.objectForKey("offerToReceiveVideo") as? Bool

		if offerToReceiveAudio == nil && offerToReceiveVideo == nil {
			self.constraints = RTCMediaConstraints()
			return
		}

		if offerToReceiveAudio == nil {
			offerToReceiveAudio = false
		}

		if offerToReceiveVideo == nil {
			offerToReceiveVideo = false
		}

		NSLog("PluginRTCPeerConnectionConstraints#init() | [offerToReceiveAudio:%@, offerToReceiveVideo:%@]",
			String(offerToReceiveAudio!), String(offerToReceiveVideo!))

		self.constraints = RTCMediaConstraints(
			mandatoryConstraints: [
				RTCPair(key: "OfferToReceiveAudio", value: offerToReceiveAudio == true ? "true" : "false"),
				RTCPair(key: "OfferToReceiveVideo", value: offerToReceiveVideo == true ? "true" : "false")
			],
			optionalConstraints: []
		)
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConstraints#deinit()")
	}


	func getConstraints() -> RTCMediaConstraints {
		NSLog("PluginRTCPeerConnectionConstraints#getConstraints()")

		return self.constraints
	}
}
