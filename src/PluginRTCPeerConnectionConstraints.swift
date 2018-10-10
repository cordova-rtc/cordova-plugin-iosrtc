import Foundation


class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints


	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")

		if pcConstraints == nil {
			self.constraints = RTCMediaConstraints.init(mandatoryConstraints: [:], optionalConstraints: [:])
			return
		}

		var	offerToReceiveAudio = pcConstraints?.object(forKey: "offerToReceiveAudio") as? Bool
		var	offerToReceiveVideo = pcConstraints?.object(forKey: "offerToReceiveVideo") as? Bool

		if offerToReceiveAudio == nil && offerToReceiveVideo == nil {
			self.constraints = RTCMediaConstraints.init(mandatoryConstraints: [:], optionalConstraints: [:])
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

		self.constraints = RTCMediaConstraints.init(
			mandatoryConstraints: [
				"OfferToReceiveAudio": offerToReceiveAudio == true ? "true" : "false",
				"OfferToReceiveVideo": offerToReceiveVideo == true ? "true" : "false"
			],
			optionalConstraints: [:]
		);
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConstraints#deinit()")
	}


	func getConstraints() -> RTCMediaConstraints {
		NSLog("PluginRTCPeerConnectionConstraints#getConstraints()")

		return self.constraints
	}
}
