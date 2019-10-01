import Foundation

class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints

	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")
		var mandatoryConstraints: [String : String] = [:]
		var optionalConstraints: [String : String] = [:]
		
		let _mandatoryConstraints = pcConstraints?.object(forKey: "mandatory") as? NSDictionary
		let _optionalConstraints = pcConstraints?.object(forKey: "optional") as? NSDictionary

		if _mandatoryConstraints != nil {
			for (key, value) in _mandatoryConstraints! {
				var finalValue: String,
					finalKey: String = key as! String;
				
				if value is Bool {
					finalValue = value as! Bool ? "true" : "false"
				} else {
					finalValue = value as! String
				}
				
				// Handle Spec for offerToReceiveAudio|offerToReceiveVideo but
				// libwebrtc still use OfferToReceiveAudio|OfferToReceiveVideo
				if (finalKey == "offerToReceiveAudio") {
					finalKey =  "OfferToReceiveAudio";
				} else if (finalKey == "offerToReceiveVideo") {
					finalKey =  "OfferToReceiveVideo";
				}
				
				mandatoryConstraints[finalKey] = finalValue
			}
		}

		if _optionalConstraints != nil {
			for (key, value) in _optionalConstraints! {
				var finalValue: String,
					finalKey: String = key as! String;
				
				if value is Bool {
					finalValue = value as! Bool ? "true" : "false"
				} else {
					finalValue = value as! String
				}
				
				// Handle Spec for offerToReceiveAudio|offerToReceiveVideo but
				// libwebrtc still use OfferToReceiveAudio|OfferToReceiveVideo
				if (finalKey == "offerToReceiveAudio") {
					finalKey =  "OfferToReceiveAudio";
				} else if (finalKey == "offerToReceiveVideo") {
					finalKey =  "OfferToReceiveVideo";
				}
				
				optionalConstraints[finalKey] = finalValue
			}
		}
		
		NSLog("PluginRTCPeerConnectionConstraints#init() | [mandatoryConstraints:%@, optionalConstraints:%@]",
			mandatoryConstraints, optionalConstraints)

		self.constraints = RTCMediaConstraints.init(
			mandatoryConstraints: mandatoryConstraints,
			optionalConstraints: optionalConstraints
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
