import Foundation


class PluginRTCPeerConnectionConfig {
	
	fileprivate let allowedSdpSemantics = [
		"plan-b": RTCSdpSemantics.planB,
		"unified-plan": RTCSdpSemantics.unifiedPlan
	]
  
	fileprivate let allowedBundlePolicy = [
		"balanced": RTCBundlePolicy.balanced,
		"max-compat": RTCBundlePolicy.maxCompat,
		"max-bundle": RTCBundlePolicy.maxBundle
	]
	
	fileprivate let allowedIceTransportPolicy = [
		"all": RTCIceTransportPolicy.all,
		"relay": RTCIceTransportPolicy.relay
	]
	
	fileprivate let allowedRtcpMuxPolicy = [
		"require": RTCRtcpMuxPolicy.require,
		"negotiate": RTCRtcpMuxPolicy.negotiate,
	]
	
	fileprivate var rtcConfiguration: RTCConfiguration

	init(pcConfig: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConfig#init()")
		
		self.rtcConfiguration = RTCConfiguration()
			
		/*
		 Since Chrome 65, this has been an experimental feature that you can opt-in to by passing
		 sdpSemantics:'unified-plan' to the RTCPeerConnection constructor, with transceivers added in M69.
		 History: https://crbug.com/799030. Canary/Dev experiments making Unified Plan the default behavior started in 71.
		 The target is to release Unified Plan by default in 72 Stable. For more information, see https://webrtc.org/web-apis/chrome/unified-plan/.
		 See: https://www.chromestatus.com/feature/5723303167655936
		*/
		
		let sdpSemanticsConfig = pcConfig?.object(forKey: "sdpSemantics") as? String;
		let sdpSemantics = (sdpSemanticsConfig != nil && allowedSdpSemantics[sdpSemanticsConfig!] != nil) ?
			allowedSdpSemantics[sdpSemanticsConfig!] : RTCSdpSemantics.unifiedPlan
		
		rtcConfiguration.sdpSemantics = sdpSemantics!;
		
		/*
		 Specifies how to handle negotiation of candidates when the remote peer is not compatible with the SDP BUNDLE standard.
		 This must be one of the values from the enum RTCBundlePolicy. If this value isn't included in the dictionary, "balanced" is assumed.
		 
		 "balanced"    On BUNDLE-aware connections, the ICE agent should gather candidates for all of the media types in use (audio, video, and data). Otherwise, the ICE agent should only negotiate one audio and video track on separate transports.
		 "max-compat"    The ICE agent should gather candidates for each track, using separate transports to negotiate all media tracks for connections which aren't BUNDLE-compatible.
		 "max-bundle"    The ICE agent should gather candidates for just one track. If the connection isn't BUNDLE-compatible, then the ICE agent should negotiate just one media track.
		 */
		
		let bundlePolicyConfig = pcConfig?.object(forKey: "bundlePolicy") as? String;
		let bundlePolicy = (bundlePolicyConfig != nil && allowedBundlePolicy[bundlePolicyConfig!] != nil) ?
								allowedBundlePolicy[bundlePolicyConfig!] : RTCBundlePolicy.balanced
		
		rtcConfiguration.bundlePolicy = bundlePolicy!;
		
		/*
		 An Array of objects of type RTCCertificate which are used by the connection for authentication.
		 If this property isn't specified, a set of certificates is generated automatically for each RTCPeerConnection instance.
		 Although only one certificate is used by a given connection, providing certificates for multiple algorithms may improve
		 the odds of successfully connecting in some circumstances. See Using certificates below for additional information.
		 This configuration option cannot be changed after it is first specified; once the certificates have been set,
		  this property is ignored in future calls to RTCPeerConnection.setConfiguration().
		 */
		// TODO certificates
		
		/*
		 An unsigned 16-bit integer value which specifies the size of the prefetched ICE candidate pool.
		 The default value is 0 (meaning no candidate prefetching will occur).
		 You may find in some cases that connections can be established more quickly by allowing the ICE agent
		 to start fetching ICE candidates before you start trying to connect, so that they're already available
		 for inspection when RTCPeerConnection.setLocalDescription() is called.
		 Changing the size of the ICE candidate pool may trigger the beginning of ICE gathering.
		 */
		
		let iceCandidatePoolSizeConfig = pcConfig?.object(forKey: "iceCandidatePoolSize") as? Int32;
		rtcConfiguration.iceCandidatePoolSize = iceCandidatePoolSizeConfig != nil ? iceCandidatePoolSizeConfig! : 0;
		
		/*
		 The current ICE transport policy; this must be one of the values from the RTCIceTransportPolicy enum.
		 If this isn't specified, "all" is assumed.
		
		 - "all"    All ICE candidates will be considered.
		 - "public"    Only ICE candidates with public IP addresses will be considered. Removed from the specification's May 13, 2016 working draft
		 - "relay"     Only ICE candidates whose IP addresses are being relayed, such as those being passed through a TURN server, will be considered.
		 */
		
		let iceTransportPolicyConfig = pcConfig?.object(forKey: "iceTransportPolicy") as? String;
		let iceTransportPolicy = (iceTransportPolicyConfig != nil && allowedIceTransportPolicy[iceTransportPolicyConfig!] != nil) ?
									allowedIceTransportPolicy[iceTransportPolicyConfig!] : RTCIceTransportPolicy.all
		
		rtcConfiguration.iceTransportPolicy = iceTransportPolicy!;
		
		/*
		 The RTCP mux policy to use when gathering ICE candidates, in order to support non-multiplexed RTCP.
		 The value must be one of those from the RTCRtcpMuxPolicy enum. The default is "require".

		 - "negotiate"    Instructs the ICE agent to gather both RTP and RTCP candidates. If the remote peer can multiplex RTCP,
						 then RTCP candidates are multiplexed atop the corresponding RTP candidates. Otherwise, both the RTP and RTCP candidates are returned, separately.
		 - "require"    Tells the ICE agent to gather ICE candidates for only RTP, and to multiplex RTCP atop them.
						 If the remote peer doesn't support RTCP multiplexing, then session negotiation fails.
		 */
		
		let rtcpMuxPolicyConfig = pcConfig?.object(forKey: "rtcpMuxPolicy") as? String;
		let rtcpMuxPolicy = (rtcpMuxPolicyConfig != nil && allowedRtcpMuxPolicy[rtcpMuxPolicyConfig!] != nil) ?
								allowedRtcpMuxPolicy[rtcpMuxPolicyConfig!] : RTCRtcpMuxPolicy.require
		
		rtcConfiguration.rtcpMuxPolicy = rtcpMuxPolicy!;
		
		/*
		 A DOMString which specifies the target peer identity for the RTCPeerConnection.
		 If this value is set (it defaults to null), the RTCPeerConnection will not connect to a remote peer
		 unless it can successfully authenticate with the given name.
		 */
		// TODO peerIdentity

		/*
		An array of RTCIceServer objects, each describing one server which may be used by the ICE agent;
		these are typically STUN and/or TURN servers. If this isn't specified, the connection attempt
		will be made with no STUN or TURN server available, which limits the connection to local peers.
		*/
		let iceServers = pcConfig?.object(forKey: "iceServers") as? [NSDictionary]

		if iceServers != nil {
			for iceServer: NSDictionary in iceServers! {
				let urlsConfig = (iceServer.object(forKey: "url") != nil ?
						iceServer.object(forKey: "url") : iceServer.object(forKey: "urls"))
				
				let urls = urlsConfig is String ? [urlsConfig as? String ?? ""] : urlsConfig as? [String] ?? nil;
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
	}

	deinit {
		NSLog("PluginRTCPeerConnectionConfig#deinit()")
	}
	
	func getConfiguration() -> RTCConfiguration {
		NSLog("PluginRTCPeerConnectionConfig#getConfiguration()")
		
		return self.rtcConfiguration
	}
}
