import Foundation


class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints

	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")
		var mandatoryConstraints: [String : String] = [:]
		var optionalConstraints: [String : String] = [:]
		
		let _mandatoryConstraints = pcConstraints?.object(forKey: "mandatory") as? NSDictionary
		let _optionalConstraints = pcConstraints?.object(forKey: "optional") as? NSDictionary
		
		// Handle constraints at the root of pcConstraints.mandatory
		if _mandatoryConstraints != nil {
			mandatoryConstraints = PluginRTCPeerConnectionConstraints.parseConstraints(constraints: _mandatoryConstraints!)
		}
		
		// Handle constraints at the root of pcConstraints
		if _optionalConstraints != nil {
			optionalConstraints = PluginRTCPeerConnectionConstraints.parseConstraints(constraints: _optionalConstraints!)
		}
		
		// Handle constraints at the root of pcConstraints.optional
		if _optionalConstraints == nil && _mandatoryConstraints != nil  {
			mandatoryConstraints = PluginRTCPeerConnectionConstraints.parseConstraints(constraints: pcConstraints!)
		}
		
		NSLog("PluginRTCPeerConnectionConstraints#init() | [mandatoryConstraints:%@, optionalConstraints:%@]",
			mandatoryConstraints, optionalConstraints)

		self.constraints = RTCMediaConstraints.init(
			mandatoryConstraints: mandatoryConstraints,
			optionalConstraints: optionalConstraints
		)
	}
	
	fileprivate static func parseConstraints(constraints: NSDictionary) -> [String : String] {
		var _constraints : [String : String] = [:]
		
		for (key, value) in constraints {
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
			
			_constraints[finalKey] = finalValue
		}
		
		return _constraints;
	}
	
	deinit {
		NSLog("PluginRTCPeerConnectionConstraints#deinit()")
	}

	func getConstraints() -> RTCMediaConstraints {
		NSLog("PluginRTCPeerConnectionConstraints#getConstraints()")

		return self.constraints
	}
}
