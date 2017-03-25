import Foundation


class PluginRTCPeerConnection : NSObject, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, RTCStatsDelegate {

	var rtcPeerConnectionFactory: RTCPeerConnectionFactory
	var rtcPeerConnection: RTCPeerConnection!
	var pluginRTCPeerConnectionConfig: PluginRTCPeerConnectionConfig
	var pluginRTCPeerConnectionConstraints: PluginRTCPeerConnectionConstraints
	// PluginRTCDataChannel dictionary.
	var pluginRTCDataChannels: [Int : PluginRTCDataChannel] = [:]
	// PluginRTCDTMFSender dictionary.
	var pluginRTCDTMFSenders: [Int : PluginRTCDTMFSender] = [:]
	var eventListener: (_ data: NSDictionary) -> Void
	var eventListenerForAddStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForRemoveStream: (_ id: String) -> Void
	var onCreateDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onGetStatsCallback: ((_ array: NSArray) -> Void)!

	init(
		rtcPeerConnectionFactory: RTCPeerConnectionFactory,
		pcConfig: NSDictionary?,
		pcConstraints: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForAddStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForRemoveStream: @escaping (_ id: String) -> Void
	) {
		NSLog("PluginRTCPeerConnection#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
		self.pluginRTCPeerConnectionConfig = PluginRTCPeerConnectionConfig(pcConfig: pcConfig)
		self.pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: pcConstraints)
		self.eventListener = eventListener
		self.eventListenerForAddStream = eventListenerForAddStream
		self.eventListenerForRemoveStream = eventListenerForRemoveStream
	}


	deinit {
		NSLog("PluginRTCPeerConnection#deinit()")
		self.pluginRTCDTMFSenders = [:]
	}


	func run() {
		NSLog("PluginRTCPeerConnection#run()")

		self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnection(
			withICEServers: self.pluginRTCPeerConnectionConfig.getIceServers(),
			constraints: self.pluginRTCPeerConnectionConstraints.getConstraints(),
			delegate: self
		)
	}


	func createOffer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createOffer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | success callback")

			let data = [
				"type": rtcSessionDescription.type,
				"sdp": rtcSessionDescription.description
			]

			callback(data as NSDictionary)
		}

		self.onCreateDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.createOffer(with: self,
			constraints: pluginRTCPeerConnectionConstraints.getConstraints())
	}


	func createAnswer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | success callback")

			let data = [
				"type": rtcSessionDescription.type,
				"sdp": rtcSessionDescription.description
			]

			callback(data as NSDictionary)
		}

		self.onCreateDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.createAnswer(with: self,
			constraints: pluginRTCPeerConnectionConstraints.getConstraints())
	}


	func setLocalDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: type, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")

			let data = [
				"type": self.rtcPeerConnection.localDescription.type,
				"sdp": self.rtcPeerConnection.localDescription.description
			]

			callback(data as NSDictionary)
		}

		self.onSetDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.setLocalDescriptionWith(self,
			sessionDescription: rtcSessionDescription
		)
	}


	func setRemoteDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: type, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback")

			let data = [
				"type": self.rtcPeerConnection.remoteDescription.type,
				"sdp": self.rtcPeerConnection.remoteDescription.description
			]

			callback(data as NSDictionary)
		}

		self.onSetDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.setRemoteDescriptionWith(self,
			sessionDescription: rtcSessionDescription
		)
	}


	func addIceCandidate(
		_ candidate: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: () -> Void
	) {
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let sdpMid = candidate.object(forKey: "sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.object(forKey: "sdpMLineIndex") as? Int ?? 0
		let candidate = candidate.object(forKey: "candidate") as? String ?? ""

		let result: Bool = self.rtcPeerConnection.add(RTCICECandidate(
			mid: sdpMid,
			index: sdpMLineIndex,
			sdp: candidate
		))

		var data: NSDictionary

		if result == true {
			if self.rtcPeerConnection.remoteDescription != nil {
				data = [
					"remoteDescription": [
						"type": self.rtcPeerConnection.remoteDescription.type,
						"sdp": self.rtcPeerConnection.remoteDescription.description
					]
				]
			} else {
				data = [
					"remoteDescription": false
				]
			}

			callback(data)
		} else {
			errback()
		}
	}


	func addStream(_ pluginMediaStream: PluginMediaStream) -> Bool {
		NSLog("PluginRTCPeerConnection#addStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return false
		}

		return self.rtcPeerConnection.add(pluginMediaStream.rtcMediaStream)
	}


	func removeStream(_ pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
	}


	func createDataChannel(
		_ dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcPeerConnection: rtcPeerConnection,
			label: label,
			options: options,
			eventListener: eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()
	}


	func RTCDataChannel_setListener(
		_ dcId: Int,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_setListener()")

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		// Set the eventListener.
		pluginRTCDataChannel!.setListener(eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)
	}


	func createDTMFSender(
		_ dsId: Int,
		track: PluginMediaStreamTrack,
		eventListener: @escaping (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDTMFSender()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDTMFSender = PluginRTCDTMFSender(
			rtcPeerConnection: rtcPeerConnection,
			track: track.rtcMediaStreamTrack,
			eventListener: eventListener
		)

		// Store the pluginRTCDTMFSender into the dictionary.
		self.pluginRTCDTMFSenders[dsId] = pluginRTCDTMFSender

		// Run it.
		pluginRTCDTMFSender.run()
	}

	func getStats(
		_ pluginMediaStreamTrack: PluginMediaStreamTrack?,
		callback: @escaping (_ data: NSArray) -> Void,
		errback: (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#getStats()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		self.onGetStatsCallback = { (array: NSArray) -> Void in
			callback(array)
		}

		if !self.rtcPeerConnection.getStatsWith(self,
			mediaStreamTrack: pluginMediaStreamTrack?.rtcMediaStreamTrack,
			statsOutputLevel: RTCStatsOutputLevelStandard) {
				errback(NSError(domain: "Cannot get peer connection stats.", code: -1, userInfo: nil))
		}
    }

	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		self.rtcPeerConnection.close()
	}


	func RTCDataChannel_sendString(
		_ dcId: Int,
		data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendString(data, callback: callback)
	}


	func RTCDataChannel_sendBinary(
		_ dcId: Int,
		data: Data,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendBinary()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendBinary(data, callback: callback)
	}


	func RTCDataChannel_close(_ dcId: Int) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.close()

		// Remove the pluginRTCDataChannel from the dictionary.
		self.pluginRTCDataChannels[dcId] = nil
	}


	func RTCDTMFSender_insertDTMF(
		_ dsId: Int,
		tones: String,
		duration: Int,
		interToneGap: Int
	) {
		NSLog("PluginRTCPeerConnection#RTCDTMFSender_insertDTMF()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		let pluginRTCDTMFSender = self.pluginRTCDTMFSenders[dsId]
		if pluginRTCDTMFSender == nil {
			return
		}

		pluginRTCDTMFSender!.insertDTMF(tones, duration: duration, interToneGap: interToneGap)
	}


	/**
	 * Methods inherited from RTCPeerConnectionDelegate.
	 */


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		signalingStateChanged newState: RTCSignalingState) {
		let state_str = PluginRTCTypes.signalingStates[newState.rawValue] as String!

		NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "signalingstatechange",
			"signalingState": state_str
		])
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		iceGatheringChanged newState: RTCICEGatheringState) {
		let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue] as String!

		NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "icegatheringstatechange",
			"iceGatheringState": state_str
		])

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		// Emit an empty candidate if iceGatheringState is "complete".
		if newState.rawValue == RTCICEGatheringComplete.rawValue && self.rtcPeerConnection.localDescription != nil {
			self.eventListener([
				"type": "icecandidate",
				// NOTE: Cannot set null as value.
				"candidate": false,
				"localDescription": [
					"type": self.rtcPeerConnection.localDescription.type,
					"sdp": self.rtcPeerConnection.localDescription.description
				]
			])
		}
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		gotICECandidate candidate: RTCICECandidate!) {
		NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:%@, sdpMLineIndex:%@, candidate:%@]",
			String(candidate.sdpMid), String(candidate.sdpMLineIndex), String(candidate.sdp))

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingClosed.rawValue {
			return
		}

		self.eventListener([
			"type": "icecandidate",
			"candidate": [
				"sdpMid": candidate.sdpMid,
				"sdpMLineIndex": candidate.sdpMLineIndex,
				"candidate": candidate.sdp
			],
			"localDescription": [
				"type": self.rtcPeerConnection.localDescription.type,
				"sdp": self.rtcPeerConnection.localDescription.description
			]
		])
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		iceConnectionChanged newState: RTCICEConnectionState) {
		let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue] as String!

		NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "iceconnectionstatechange",
			"iceConnectionState": state_str
		])
	}


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		addedStream rtcMediaStream: RTCMediaStream!) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)

		pluginMediaStream.run()

		// Let the plugin store it in its dictionary.
		self.eventListenerForAddStream(pluginMediaStream)

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener([
			"type": "addstream",
			"stream": pluginMediaStream.getJSON()
		])
	}


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		removedStream rtcMediaStream: RTCMediaStream!) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		// Let the plugin remove it from its dictionary.
		self.eventListenerForRemoveStream(rtcMediaStream.label)

		self.eventListener([
			"type": "removestream",
			"streamId": rtcMediaStream.label  // NOTE: No "id" property yet.
		])
	}


	func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		self.eventListener([
			"type": "negotiationneeded"
		])
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didOpen rtcDataChannel: RTCDataChannel!) {
		NSLog("PluginRTCPeerConnection | ondatachannel")

		let dcId = PluginUtils.randomInt(10000, max:99999)
		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcDataChannel: rtcDataChannel
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()

		// Fire the 'datachannel' event so the JS will create a new RTCDataChannel.
		self.eventListener([
			"type": "datachannel",
			"channel": [
				"dcId": dcId,
				"label": rtcDataChannel.label,
				"ordered": rtcDataChannel.isOrdered,
				"maxPacketLifeTime": rtcDataChannel.maxRetransmitTime,
				"maxRetransmits": rtcDataChannel.maxRetransmits,
				"protocol": rtcDataChannel.`protocol`,
				"negotiated": rtcDataChannel.isNegotiated,
				"id": rtcDataChannel.streamId,
				"readyState": PluginRTCTypes.dataChannelStates[rtcDataChannel.state.rawValue] as String!,
				"bufferedAmount": rtcDataChannel.bufferedAmount
			]
		])
	}


	/**
	 * Methods inherited from RTCSessionDescriptionDelegate.
	 */


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		didCreateSessionDescription rtcSessionDescription: RTCSessionDescription!, error: Error!) {
		if error == nil {
			self.onCreateDescriptionSuccessCallback(rtcSessionDescription)
		} else {
			self.onCreateDescriptionFailureCallback(error)
		}
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didSetSessionDescriptionWithError error: Error!) {
		if error == nil {
			self.onSetDescriptionSuccessCallback()
		} else {
			self.onSetDescriptionFailureCallback(error)
		}
	}

	/**
	* Methods inherited from RTCStatsDelegate
	*/
    
	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didGetStats stats: [Any]!) {

		var jsStats = [NSDictionary]()

		for stat in stats as NSArray {
			var jsValues = Dictionary<String,String>()

			for pair in (stat as AnyObject).values as! [RTCPair] {
				jsValues[pair.key] = pair.value;
			}

			jsStats.append(["reportId": (stat as! RTCStatsReport).reportId, "type": (stat as! RTCStatsReport).type, "timestamp": (stat as! RTCStatsReport).timestamp, "values": jsValues]);

		}

		//self.onGetStatsCallback(jsStats);
	}
}
