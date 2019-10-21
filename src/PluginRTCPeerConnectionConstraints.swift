import Foundation


class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints

	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")
		var mandatoryConstraints: [String : String] = [:]
		var optionalConstraints: [String : String] = [:]
		
		// Handle constraints at the root of pcConstraints.mandatory
		let _mandatoryConstraints = pcConstraints?.object(forKey: "mandatory") as? NSDictionary
		if _mandatoryConstraints != nil {
			mandatoryConstraints = PluginRTCPeerConnectionConstraints.parseConstraints(constraints: _mandatoryConstraints!)
		}
		
		// Handle constraints at the root of pcConstraints.optional
		let _optionalConstraints = pcConstraints?.object(forKey: "optional") as? NSArray
		if _optionalConstraints != nil {
			optionalConstraints = PluginRTCPeerConnectionConstraints.parseOptionalConstraints(optionalConstraints: _optionalConstraints!)
		}
		
		// Handle constraints at the root of pcConstraints
		if pcConstraints != nil && _optionalConstraints == nil && _mandatoryConstraints == nil  {
			mandatoryConstraints = PluginRTCPeerConnectionConstraints.parseConstraints(constraints: pcConstraints!)
		}
		
		NSLog("PluginRTCPeerConnectionConstraints#init() | [mandatoryConstraints:%@, optionalConstraints:%@]",
			mandatoryConstraints, optionalConstraints)

		self.constraints = RTCMediaConstraints.init(
			mandatoryConstraints: mandatoryConstraints,
			optionalConstraints: optionalConstraints
		)
	}
	
	// Custom proprietary constrains in libwebrtc
	fileprivate static let allowedOptionalConstraints : Array = [
		// Temporary pseudo-constraints used to enable DTLS-SRT
		"DtlsSrtpKeyAgreement",
		// Constraint to enable IPv6
		"googIPv6",
		// Constraint to enable combined audio+video bandwidth estimation.
		"googImprovedWifiBwe",
		// Temporary pseudo-constraint for enabling DSCP
		"googDscp",
		// If enabled, will lower outgoing video quality and video resolution
		"googCpuOveruseDetection",
		// Min CPU load (percents), used in pair with
		"googCpuUnderuseThreshold",
		// Max CPU (percents), used in pair with googCpuOveruseDetection
		"googCpuOveruseThreshold",
		// Cause video track to be automatically disabled if the detected bandwidth drops below "min bitrate"
		"googSuspendBelowMinBitrate",
		//"googScreencastMinBitrate"
	]
	
	fileprivate static func parseOptionalConstraints(optionalConstraints: NSArray) -> [String : String] {
		var _constraints : [String : String] = [:]
		
		for optionalConstraint in optionalConstraints {
			if (optionalConstraint is NSDictionary) {
				for (key, value) in optionalConstraint as! NSDictionary {
					let finalKey: String = key as! String;
					
					// Parse only allowedOptionalConstraints
					if (allowedOptionalConstraints.firstIndex(of: finalKey) != nil) {
					   if value is Int32 {
						   _constraints[finalKey] = String(describing: value);
					   } else if value is Bool {
						   _constraints[finalKey] = value as! Bool ? "true" : "false"
					   } else if value is String {
						   _constraints[finalKey] = (value as! String)
					   }
					}
				}
			}
		}
		
		return _constraints;
	}
	
	// https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/createOffer#RTCOfferOptions_dictionary
	// TODO TODO voiceActivityDetection This option defaults to true
	fileprivate static let allowedConstraints : Array = [
		"iceRestart", 
		"OfferToReceiveVideo", 
		"OfferToReceiveAudio",
		"voiceActivityDetection"
	]
	
	fileprivate static func parseConstraints(constraints: NSDictionary) -> [String : String] {
		var _constraints : [String : String] = [:]
		
		for (key, value) in constraints {
			var finalValue: String,
				finalKey: String = key as! String;
			
			if value is Bool {
				finalValue = value as! Bool ? "true" : "false"
			} else if value is String {
				finalValue = value as! String
			} else {
				continue
			}
			
			// Handle Spec for offerToReceiveAudio|offerToReceiveVideo but
			// libwebrtc still use OfferToReceiveAudio|OfferToReceiveVideo
			if (finalKey == "offerToReceiveAudio") {
				finalKey =  "OfferToReceiveAudio";
			} else if (finalKey == "offerToReceiveVideo") {
				finalKey =  "OfferToReceiveVideo";
			}
			
			// Filter to avoid injection
			if (allowedConstraints.firstIndex(of: finalKey) != nil) {
				_constraints[finalKey] = finalValue
			}
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
