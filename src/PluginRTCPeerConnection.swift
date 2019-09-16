import Foundation

class PluginRTCPeerConnection : NSObject, RTCPeerConnectionDelegate {

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
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onGetStatsCallback: ((_ array: NSArray) -> Void)!
	var streamIds: [String] = []
	var isAudioInputSelected: Bool = false

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

		let config = RTCConfiguration();
		config.iceServers = self.pluginRTCPeerConnectionConfig.getIceServers();
		self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnection(with: config, constraints: self.pluginRTCPeerConnectionConstraints.getConstraints(), delegate: self)
	}

	func createOffer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createOffer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.rtcPeerConnection.offer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: { (des: RTCSessionDescription?, error: Error?) in

			if(error != nil){
				NSLog("PluginRTCPeerConnection#createOffer() | failure callback: %@", String(describing: error))
				
				errback(error!)
				return
			}
			
			NSLog("PluginRTCPeerConnection#createOffer() | success callback: %@ %@", self.rtcSdpTypeToString(type: des!.type), des!.sdp)

			let data = [
				"type": self.rtcSdpTypeToString(type: des!.type),
				"sdp": des!.sdp
				] as [String : Any]

			callback(data as NSDictionary)
		})
	}


	func createAnswer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)
		
		self.rtcPeerConnection.answer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: { (des: RTCSessionDescription?, error: Error?) in
	
			if(error != nil){
				NSLog("PluginRTCPeerConnection#createOffer() | failure callback: %@", String(describing: error))

				errback(error!)
				return
			}

			NSLog("PluginRTCPeerConnection#createOffer() | success callback %@ %@", self.rtcSdpTypeToString(type: des!.type), des!.sdp)

			let data = [
				"type": self.rtcSdpTypeToString(type: des!.type),
				"sdp": des!.sdp
				] as [String : Any]
			
			callback(data as NSDictionary)
		})
	}
	
	func rtcSdpTypeToString(type: RTCSdpType) -> String {
		if(type == RTCSdpType.offer){
			return "offer";
		}else if(type == RTCSdpType.prAnswer){
			return "pranswer";
		}else if(type == RTCSdpType.answer){
			return "answer";
		}else{
			return "answer";
		}
	}
	
	func rtcSdpTypeParser(type: String) -> RTCSdpType {
		if(type == "answer"){
			return RTCSdpType.answer;
		}else if(type == "offer"){
			return RTCSdpType.offer;
		}else if(type == "pranswer"){
			return RTCSdpType.prAnswer
		}else{
			return RTCSdpType.answer;
		}
	}

	func setLocalDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: rtcSdpTypeParser(type: type), sdp: sdp)

		self.rtcPeerConnection.setLocalDescription(rtcSessionDescription, completionHandler: { (error: Error?) in
			if(error != nil){
				NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@", String(describing: error))
				errback(error!)
				return;
			}

			NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")

			let data = [
				"type": self.rtcSdpTypeToString(type: self.rtcPeerConnection.localDescription!.type),
				"sdp": self.rtcPeerConnection.localDescription!.sdp
			]

			callback(data as NSDictionary)
		});
	}


	func setRemoteDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let rtcSessionDescription = RTCSessionDescription(type: rtcSdpTypeParser(type: type), sdp: sdp)

		self.rtcPeerConnection.setRemoteDescription(rtcSessionDescription, completionHandler: { (error: Error?) in
			if(error != nil){
				NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: %@", String(describing: error))
				errback(error!)
				return;
			}

			NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback")

			let data = [
				"type": self.rtcSdpTypeToString(type: self.rtcPeerConnection.remoteDescription!.type),
				"sdp": self.rtcPeerConnection.remoteDescription!.sdp
			]

			callback(data as NSDictionary)
		});
	}


	func addIceCandidate(
		_ candidate: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: () -> Void
	) {
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let sdpMid = candidate.object(forKey: "sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.object(forKey: "sdpMLineIndex") as? Int32 ?? 0
		let candidate = candidate.object(forKey: "candidate") as? String ?? ""

		self.rtcPeerConnection.add(RTCIceCandidate.init(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid))

		let result = true

		// TODO Why here and is it still needed
		if !self.isAudioInputSelected {
			PluginEnumerateDevices.setPreferredInput()
			self.isAudioInputSelected = true
		}

		if result == true {
			var data: NSDictionary
			if self.rtcPeerConnection.remoteDescription != nil {
				data = [
					"remoteDescription": [
						"type": rtcSdpTypeToString(type: self.rtcPeerConnection.remoteDescription!.type),
						"sdp": self.rtcPeerConnection.remoteDescription!.description
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

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return false
		}
		
		self.rtcPeerConnection.add(pluginMediaStream.rtcMediaStream)
		return true
	}

	func removeStream(_ pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
	}

    func addTrack(_ track: PluginMediaStreamTrack) -> Bool {
        NSLog("PluginRTCPeerConnection#addTrack()")
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return false
        }
        
        return true;
    }
    
    func removeTrack(_ track: PluginMediaStreamTrack) {
        NSLog("PluginRTCPeerConnection#removeTrack()")
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
    }

	func createDataChannel(
		_ dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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
		callback: @escaping (_ data: [[String:Any]]) -> Void,
		errback: (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#getStats()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.stats(for: pluginMediaStreamTrack?.rtcMediaStreamTrack, statsOutputLevel: RTCStatsOutputLevel.standard, completionHandler: { (stats: [RTCLegacyStatsReport]) in
			var data: [[String:Any]] = []
			for i in 0 ..< stats.count {
				let report: RTCLegacyStatsReport = stats[i]
				data.append([
					"reportId" : report.reportId,
					"type" : report.type,
					"timestampt" : report.timestamp,
					"values" : report.values
					])
			}
			NSLog("Stats:\n %@", data)
			callback(data)
		})
	}

	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}
		
		for streamId: String in streamIds {
			self.eventListenerForRemoveStream(streamId)
		}

		self.rtcPeerConnection.close()
	}


	func RTCDataChannel_sendString(
		_ dcId: Int,
		data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
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
	
	/** Called when the SignalingState changed. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
		let state_str = PluginRTCTypes.signalingStates[stateChanged.rawValue] as String! ?? "default"

		NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "signalingstatechange",
			"signalingState": state_str
			])
	}

	/** Called when media is received on a new stream from remote peer. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = PluginMediaStream(rtcMediaStream: stream)

		pluginMediaStream.run()

		// Let the plugin store it in its dictionary.
		streamIds.append(stream.streamId)
		self.eventListenerForAddStream(pluginMediaStream)

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener([
			"type": "addstream",
			"stream": pluginMediaStream.getJSON()
			])
	}
	 
	/** Called when a remote peer closes a stream. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		// Let the plugin remove it from its dictionary.
		self.eventListenerForRemoveStream(stream.streamId)

		self.eventListener([
			"type": "removestream",
			"streamId": stream.streamId
			])
	}

	/** Called when negotiation is needed, for example ICE has restarted. */
	func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		self.eventListener([
			"type": "negotiationneeded"
			])
	}
	 
	/** Called any time the IceConnectionState changes. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue] as String!

		NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "iceconnectionstatechange",
			"iceConnectionState": state_str!
			])
	}

	/** Called any time the IceGatheringState changes. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
		let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue] as String! ?? "default"

		NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "icegatheringstatechange",
			"iceGatheringState": state_str
			])

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		// Emit an empty candidate if iceGatheringState is "complete".
		if newState.rawValue == RTCIceGatheringState.complete.rawValue && self.rtcPeerConnection.localDescription != nil {
			self.eventListener([
				"type": "icecandidate",
				// NOTE: Cannot set null as value.
				"candidate": false,
				"localDescription": [
					"type": rtcSdpTypeToString(type: self.rtcPeerConnection.localDescription!.type),
					"sdp": self.rtcPeerConnection.localDescription!.description
					]
			])
		}
	}
 
	/** New ice candidate has been found. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
		NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:%@, sdpMLineIndex:%@, candidate:%@]",
			String(describing: candidate.sdpMid), String(candidate.sdpMLineIndex), String(candidate.sdp))

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.eventListener([
			"type": "icecandidate",
			"candidate": [
				"sdpMid": candidate.sdpMid!,
				"sdpMLineIndex": candidate.sdpMLineIndex,
				"candidate": candidate.sdp
			],
			"localDescription": [
				"type": rtcSdpTypeToString(type: self.rtcPeerConnection.localDescription!.type),
				"sdp": self.rtcPeerConnection.localDescription!.description
			]
		])
	}
	 
	/** Called when a group of local Ice candidates have been removed. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
	
	}
	 
	/** New data channel has been opened. */
	func peerConnection(_ peerConnection: RTCPeerConnection,
						didOpen rtcDataChannel: RTCDataChannel) {
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
				"readyState": pluginRTCDataChannel.getState(),
				"bufferedAmount": rtcDataChannel.bufferedAmount
			]
		])
	}
}
