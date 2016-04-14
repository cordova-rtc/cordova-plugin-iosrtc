import Foundation


class PluginRTCPeerConnectionConfig {
	private var iceServers: [RTCICEServer] = []


	init(pcConfig: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConfig#init()")

		let iceServers = pcConfig?.objectForKey("iceServers") as? [NSDictionary]

		if iceServers == nil {
			return
		}

		for iceServer: NSDictionary in iceServers! {
			let url = iceServer.objectForKey("url") as? String
			let username = iceServer.objectForKey("username") as? String ?? ""
			let password = iceServer.objectForKey("credential") as? String ?? ""

			if (url != nil) {
				NSLog("PluginRTCPeerConnectionConfig#init() | adding ICE server [url:'%@', username:'%@', password:'******']",
					String(url!), String(username))

				self.iceServers.append(RTCICEServer(
					URI: NSURL(string: url!),
					username: username,
					password: password
				))
			}
		}
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConfig#deinit()")
	}


	func getIceServers() -> [RTCICEServer] {
		NSLog("PluginRTCPeerConnectionConfig#getIceServers()")

		return self.iceServers
	}
}
