import Foundation


class PluginRTCPeerConnection : NSObject, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate {
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory
	var rtcPeerConnection: RTCPeerConnection!
	var pluginRTCPeerConnectionConfig: PluginRTCPeerConnectionConfig
	var pluginRTCPeerConnectionConstraints: PluginRTCPeerConnectionConstraints
	// PluginRTCDataChannel dictionary.
	var pluginRTCDataChannels: [Int : PluginRTCDataChannel] = [:]
	var eventListener: (data: NSDictionary) -> Void
	var eventListenerForAddStream: (pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForRemoveStream: (id: String) -> Void
	var onCreateDescriptionSuccessCallback: ((rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateDescriptionFailureCallback: ((error: NSError) -> Void)!
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((error: NSError) -> Void)!


	init(
		rtcPeerConnectionFactory: RTCPeerConnectionFactory,
		pcConfig: NSDictionary?,
		pcConstraints: NSDictionary?,
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForAddStream: (pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForRemoveStream: (id: String) -> Void
	) {
		NSLog("PluginRTCPeerConnection#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
		self.pluginRTCPeerConnectionConfig = PluginRTCPeerConnectionConfig(pcConfig: pcConfig)
		self.pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: pcConstraints)
		self.eventListener = eventListener
		self.eventListenerForAddStream = eventListenerForAddStream
		self.eventListenerForRemoveStream = eventListenerForRemoveStream
	}


	func run() {
		NSLog("PluginRTCPeerConnection#run()")

		self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnectionWithICEServers(
			self.pluginRTCPeerConnectionConfig.getIceServers(),
			constraints: self.pluginRTCPeerConnectionConstraints.getConstraints(),
			delegate: self
		)
	}


	func createOffer(
		options: NSDictionary?,
		callback: (data: NSDictionary) -> Void,
		errback: (error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createOffer()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | success callback [type:\(rtcSessionDescription.type)]")

			let data = [
				"type": rtcSessionDescription.type,
				"sdp": rtcSessionDescription.description
			]

			callback(data: data)
		}

		self.onCreateDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | failure callback: \(error)")

			errback(error: error)
		}

		self.rtcPeerConnection.createOfferWithDelegate(self,
			constraints: pluginRTCPeerConnectionConstraints.getConstraints())
	}


	func createAnswer(
		options: NSDictionary?,
		callback: (data: NSDictionary) -> Void,
		errback: (error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | success callback [type:\(rtcSessionDescription.type)]")

			let data = [
				"type": rtcSessionDescription.type,
				"sdp": rtcSessionDescription.description
			]

			callback(data: data)
		}

		self.onCreateDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | failure callback: \(error)")

			errback(error: error)
		}

		self.rtcPeerConnection.createAnswerWithDelegate(self,
			constraints: RTCMediaConstraints())
	}


	func setLocalDescription(
		desc: NSDictionary,
		callback: (data: NSDictionary) -> Void,
		errback: (error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let type = desc.objectForKey("type") as? String ?? ""
		let sdp = desc.objectForKey("sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: type, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { () -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")

			let data = [
				"type": self.rtcPeerConnection.localDescription.type,
				"sdp": self.rtcPeerConnection.localDescription.description
			]

			callback(data: data)
		}

		self.onSetDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: \(error)")

			errback(error: error)
		}

		self.rtcPeerConnection.setLocalDescriptionWithDelegate(self,
			sessionDescription: rtcSessionDescription
		)
	}


	func setRemoteDescription(
		desc: NSDictionary,
		callback: (data: NSDictionary) -> Void,
		errback: (error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let type = desc.objectForKey("type") as? String ?? ""
		let sdp = desc.objectForKey("sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: type, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { () -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback")

			let data = [
				"type": self.rtcPeerConnection.remoteDescription.type,
				"sdp": self.rtcPeerConnection.remoteDescription.description
			]

			callback(data: data)
		}

		self.onSetDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: \(error)")

			errback(error: error)
		}

		self.rtcPeerConnection.setRemoteDescriptionWithDelegate(self,
			sessionDescription: rtcSessionDescription
		)
	}


	func addIceCandidate(
		candidate: NSDictionary,
		callback: (data: NSDictionary) -> Void,
		errback: () -> Void
	) {
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let sdpMid = candidate.objectForKey("sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.objectForKey("sdpMLineIndex") as? Int ?? 0
		let candidate = candidate.objectForKey("candidate") as? String ?? ""

		let result: Bool = self.rtcPeerConnection.addICECandidate(RTCICECandidate(
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

			callback(data: data)
		} else {
			errback()
		}
	}


	func addStream(pluginMediaStream: PluginMediaStream) -> Bool {
		NSLog("PluginRTCPeerConnection#addStream()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return false
		}

		return self.rtcPeerConnection.addStream(pluginMediaStream.rtcMediaStream)
	}


	func removeStream(pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		self.rtcPeerConnection.removeStream(pluginMediaStream.rtcMediaStream)
	}


	func createDataChannel(
		dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: (data: NSData) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
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
		dcId: Int,
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: (data: NSData) -> Void
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


	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		self.rtcPeerConnection.close()
	}


	func RTCDataChannel_sendString(
		dcId: Int,
		data: String,
		callback: (data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendString(data, callback: callback)
	}


	func RTCDataChannel_sendBinary(
		dcId: Int,
		data: NSData,
		callback: (data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendBinary()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendBinary(data, callback: callback)
	}


	func RTCDataChannel_close(dcId: Int) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_close()")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
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


	/**
	 * Methods inherited from RTCPeerConnectionDelegate.
	 */


	func peerConnection(peerConnection: RTCPeerConnection!,
		signalingStateChanged newState: RTCSignalingState) {
		let state_str = PluginRTCTypes.signalingStates[newState.value] as String!

		NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:\(state_str)]")

		self.eventListener(data: [
			"type": "signalingstatechange",
			"signalingState": state_str
		])
	}


	func peerConnection(peerConnection: RTCPeerConnection!,
		iceGatheringChanged newState: RTCICEGatheringState) {
		let state_str = PluginRTCTypes.iceGatheringStates[newState.value] as String!

		NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:\(state_str)]")

		self.eventListener(data: [
			"type": "icegatheringstatechange",
			"iceGatheringState": state_str
		])

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		// Emit an empty candidate if iceGatheringState is "complete".
		if newState.value == RTCICEGatheringComplete.value && self.rtcPeerConnection.localDescription != nil {
			self.eventListener(data: [
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


	func peerConnection(peerConnection: RTCPeerConnection!,
		gotICECandidate candidate: RTCICECandidate!) {
		NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:\(candidate.sdpMid), sdpMLineIndex:\(candidate.sdpMLineIndex), candidate:\(candidate.sdp)]")

		if self.rtcPeerConnection.signalingState.value == RTCSignalingClosed.value {
			return
		}

		self.eventListener(data: [
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


	func peerConnection(peerConnection: RTCPeerConnection!,
		iceConnectionChanged newState: RTCICEConnectionState) {
		let state_str = PluginRTCTypes.iceConnectionStates[newState.value] as String!

		NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:\(state_str)]")

		self.eventListener(data: [
			"type": "iceconnectionstatechange",
			"iceConnectionState": state_str
		])
	}


	func peerConnection(rtcPeerConnection: RTCPeerConnection!,
		addedStream rtcMediaStream: RTCMediaStream!) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
		pluginMediaStream.run()

		// Let the plugin store it in its dictionary.
		self.eventListenerForAddStream(pluginMediaStream: pluginMediaStream)

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener(data: [
			"type": "addstream",
			"stream": pluginMediaStream.getJSON()
		])
	}


	func peerConnection(rtcPeerConnection: RTCPeerConnection!,
		removedStream rtcMediaStream: RTCMediaStream!) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		// Let the plugin remove it from its dictionary.
		self.eventListenerForRemoveStream(id: rtcMediaStream.label)

		self.eventListener(data: [
			"type": "removestream",
			"streamId": rtcMediaStream.label  // NOTE: No "id" property yet.
		])
	}


	func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		self.eventListener(data: [
			"type": "negotiationneeded"
		])
	}


	func peerConnection(peerConnection: RTCPeerConnection!,
		didOpenDataChannel rtcDataChannel: RTCDataChannel!) {
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
		self.eventListener(data: [
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
				"readyState": PluginRTCTypes.dataChannelStates[rtcDataChannel.state.value] as String!,
				"bufferedAmount": rtcDataChannel.bufferedAmount
			]
		])
	}


	/**
	 * Methods inherited from RTCSessionDescriptionDelegate.
	 */


	func peerConnection(rtcPeerConnection: RTCPeerConnection!,
		didCreateSessionDescription rtcSessionDescription: RTCSessionDescription!, error: NSError!) {
		if error == nil {
			self.onCreateDescriptionSuccessCallback(rtcSessionDescription: rtcSessionDescription)
		} else {
			self.onCreateDescriptionFailureCallback(error: error)
		}
	}


	func peerConnection(peerConnection: RTCPeerConnection!,
		didSetSessionDescriptionWithError error: NSError!) {
		if error == nil {
			self.onSetDescriptionSuccessCallback()
		} else {
			self.onSetDescriptionFailureCallback(error: error)
		}
	}
}
