import Foundation


class PluginRTCPeerConnectionConfig {
	fileprivate var rtcConfiguration: RTCConfiguration


	init(pcConfig: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConfig#init()")
		
		self.rtcConfiguration = RTCConfiguration()

		let iceServers = pcConfig?.object(forKey: "iceServers") as? [NSDictionary]

		if iceServers == nil {
			return
		}

		for iceServer: NSDictionary in iceServers! {
			let urls = iceServer.object(forKey: "urlStrings") as? [String] ?? nil
			let username = iceServer.object(forKey: "username") as? String ?? ""
			let password = iceServer.object(forKey: "credential") as? String ?? ""

			if (urls != nil && urls!.count > 0) {
				NSLog("PluginRTCPeerConnectionConfig#init() | adding ICE server [url:'%@', username:'%@', password:'******']",
					  String(urls![0]), String(username))

				self.rtcConfiguration.iceServers.append(RTCIceServer(
					urlStrings: urls!,
					username: username,
					credential: password
				))
			}
		}
	}

	deinit {
		NSLog("PluginRTCPeerConnectionConfig#deinit()")
	}
	
	func getConfiguration() -> RTCConfiguration {
		NSLog("PluginRTCPeerConnectionConfig#getConfiguration()")
		
		return self.rtcConfiguration
	}
}
