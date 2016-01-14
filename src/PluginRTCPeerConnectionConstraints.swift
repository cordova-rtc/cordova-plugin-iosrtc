import Foundation


class PluginRTCPeerConnectionConstraints {
	private var constraints: RTCMediaConstraints


	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")

		if pcConstraints == nil {
			self.constraints = RTCMediaConstraints()
			return
		}

		var mandatoryPairArray:[RTCPair] = []
		var optionalPairArray:[RTCPair] = []

		let mandatoryConstraints = pcConstraints?.objectForKey("mandatory") as? NSDictionary
		let optionalConstraints = pcConstraints?.objectForKey("optional") as? NSDictionary

		if mandatoryConstraints != nil {
			for (key, value) in mandatoryConstraints! {
				var finalValue: String;
				if value is Bool {
					finalValue = value as! Bool ? "true" : "false"
				} else {
					finalValue = value as! String
				}
				mandatoryPairArray.append(RTCPair(key: key as! String, value: finalValue))
			}
		}

		if optionalConstraints != nil {
			for (key, value) in optionalConstraints! {
				var finalValue: String;
				if value is Bool {
					finalValue = value as! Bool ? "true" : "false"
				} else {
					finalValue = value as! String
				}
				optionalPairArray.append(RTCPair(key: key as! String, value: finalValue))
			}
		}

		self.constraints = RTCMediaConstraints(
			mandatoryConstraints: mandatoryPairArray,
			optionalConstraints: optionalPairArray
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
