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
	// PluginRTCRtpTransceiver dictionary.
	var pluginRTCRtpTransceivers: [Int : PluginRTCRtpTransceiver] = [:]
	var eventListener: (_ data: NSDictionary) -> Void
	var eventListenerForAddStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForRemoveStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForAddTrack: (_ pluginMediaStreamTrack: PluginMediaStreamTrack) -> Void
	var eventListenerForRemoveTrack: (_ pluginMediaStreamTrack: PluginMediaStreamTrack) -> Void

	var onCreateLocalDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateLocalDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onCreateRemoteDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateRemoteDescriptionFailureCallback: ((_ error: Error) -> Void)!

	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: Error) -> Void)!

	var onGetStatsCallback: ((_ array: NSArray) -> Void)!

	var pluginMediaStreams: [String : PluginMediaStream]! = [:]
	var pluginMediaTracks: [String : PluginMediaStreamTrack]! = [:]

	var pluginRTCRtpSenders: [Int : PluginRTCRtpSender] = [:]
	var pluginRTCRtpReceivers: [Int : PluginRTCRtpReceiver] = [:]

	var isAudioInputSelected: Bool = false

	init(
		rtcPeerConnectionFactory: RTCPeerConnectionFactory,
		pcConfig: NSDictionary?,
		pcConstraints: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForAddStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForRemoveStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForAddTrack: @escaping (_ pluginMediaStreamTrack: PluginMediaStreamTrack) -> Void,
		eventListenerForRemoveTrack: @escaping (_ pluginMediaStreamTrack: PluginMediaStreamTrack) -> Void
	) {
		NSLog("PluginRTCPeerConnection#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
		self.pluginRTCPeerConnectionConfig = PluginRTCPeerConnectionConfig(pcConfig: pcConfig)
		self.pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: pcConstraints)
		self.eventListener = eventListener
		self.eventListenerForAddStream = eventListenerForAddStream
		self.eventListenerForRemoveStream = eventListenerForRemoveStream
		self.eventListenerForAddTrack = eventListenerForAddTrack
		self.eventListenerForRemoveTrack = eventListenerForRemoveTrack
	}

	deinit {
		NSLog("PluginRTCPeerConnection#deinit()")
		self.pluginRTCDTMFSenders = [:]
        self.pluginRTCRtpTransceivers = [:]
	}

	func run() {
		NSLog("PluginRTCPeerConnection#run()")

		self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnection(
			with: self.pluginRTCPeerConnectionConfig.getConfiguration(),
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

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)


		self.onCreateLocalDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | success callback")

			let data = [
				"type": RTCSessionDescription.string(for: rtcSessionDescription.type),
				"sdp": rtcSessionDescription.sdp,
				"transceivers": self.getTransceiversJSON()
			] as [String : Any]

			callback(data as NSDictionary)
		}

		self.onCreateLocalDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.offer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: {
			(sdp: RTCSessionDescription?, error: Error?) in
			if (error == nil) {
				self.onCreateLocalDescriptionSuccessCallback(sdp!);
			} else {
				self.onCreateLocalDescriptionFailureCallback(error!);
			}
		})
	}


	func createAnswer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateRemoteDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | success callback")

			let data = [
				"type": RTCSessionDescription.string(for: rtcSessionDescription.type),
				"sdp": rtcSessionDescription.sdp,
				"transceivers": self.getTransceiversJSON()
			] as [String : Any]

			callback(data as NSDictionary)
		}

		self.onCreateRemoteDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.answer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: {
			(sdp: RTCSessionDescription?, error: Error?) in
			if (error == nil) {
				self.onCreateRemoteDescriptionSuccessCallback(sdp!)
			} else {
				self.onCreateRemoteDescriptionFailureCallback(error!)
			}
		})
	}

	func setLocalDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let sdpType = RTCSessionDescription.type(for: type)
		let rtcSessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")
			var descType = ""
			var descSDP = ""
			if self.rtcPeerConnection.localDescription != nil {
				descType = RTCSessionDescription.string(for: self.rtcPeerConnection.localDescription!.type)
				descSDP = self.rtcPeerConnection.localDescription!.sdp
			}
			let data = [
				"type": descType,
				"sdp": descSDP,
				"transceivers": self.getTransceiversJSON()
			] as [String : Any]

			callback(data as NSDictionary)
		}

		self.onSetDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@ description %@",
						String(describing: error), desc)

			errback(error)
		}

		// TODO: Would transceivers with mid=null get their mid's assigned after
		 // setLocalDescription call? Investigate...
		 //
		 // Reference:
		 // Something I overlooked last year is that transceiver.mid is null before setLocalDescription. We avoided 
		 // that problem above by establishing the connection ahead of sending anything, but this makes mid useless 
		 // for correlating in the initial negotiation.
		 // https://blog.mozilla.org/webrtc/rtcrtptransceiver-explored/

		self.rtcPeerConnection.setLocalDescription(rtcSessionDescription, completionHandler: {
			(error: Error?) in
			if (error == nil) {
				self.onSetDescriptionSuccessCallback();
			} else {
				self.onSetDescriptionFailureCallback(error!);
			}
		})
	}


	func setRemoteDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
		let sdpType = RTCSessionDescription.type(for: type)
		let rtcSessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback")

			let data = [
				"type": RTCSessionDescription.string(for: self.rtcPeerConnection.remoteDescription!.type),
				"sdp": self.rtcPeerConnection.remoteDescription!.sdp,
				"transceivers": self.getTransceiversJSON()
            ] as NSDictionary

			callback(data)
		}

		self.onSetDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}

		self.rtcPeerConnection.setRemoteDescription(rtcSessionDescription, completionHandler: {
			(error: Error?) in
			if (error == nil) {
				self.onSetDescriptionSuccessCallback();
			} else {
				self.onSetDescriptionFailureCallback(error!);
			}
		})
	}

	func addIceCandidate(
		_ candidate: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: () -> Void
	) {
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let sdpMid = candidate.object(forKey: "sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.object(forKey: "sdpMLineIndex") as? Int32 ?? 0
		let candidate = candidate.object(forKey: "candidate") as? String ?? ""

		self.rtcPeerConnection!.add(RTCIceCandidate(
			sdp: candidate,
			sdpMLineIndex: sdpMLineIndex,
			sdpMid: sdpMid
		))

		// TODO detect RTCIceCandidate failure
		let result = true

		// TODO check if it still needed or moved elsewhere
		if !self.isAudioInputSelected {
			PluginRTCAudioController.restoreInputOutputAudioDevice()
			self.isAudioInputSelected = true
		}

		if result == true {
			var data: NSDictionary
			if self.rtcPeerConnection.remoteDescription != nil {
				data = [
					"remoteDescription": [
						"type": RTCSessionDescription.string(for: self.rtcPeerConnection.remoteDescription!.type),
						"sdp": self.rtcPeerConnection.remoteDescription!.sdp
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

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return false
		}

		if (IsUnifiedPlan()) {

			var streamAdded : Bool = false;
			let streamId = pluginMediaStream.rtcMediaStream.streamId;
			for (_, pluginMediaTrack) in pluginMediaStream.audioTracks {
				let pluginRTCRtpTransceiverId = self.createIdFor(collection: self.pluginRTCRtpTransceivers)
				let pluginRTCRtpReceiverId = self.createIdFor(collection: self.pluginRTCRtpReceivers)
				let pluginRTCRtpSenderId = self.createIdFor(collection: self.pluginRTCRtpSenders)
				let pluginRTCRtpSender = self.addTrack(pluginMediaTrack, pluginRTCRtpTransceiverId, pluginRTCRtpReceiverId, pluginRTCRtpSenderId, [streamId])
				streamAdded = streamAdded && (pluginRTCRtpSender != nil)
			}

			for (_, pluginMediaTrack) in pluginMediaStream.videoTracks {
				let pluginRTCRtpTransceiverId = self.createIdFor(collection: self.pluginRTCRtpTransceivers)
				let pluginRTCRtpReceiverId = self.createIdFor(collection: self.pluginRTCRtpReceivers)
				let pluginRTCRtpSenderId = self.createIdFor(collection: self.pluginRTCRtpSenders)
				let pluginRTCRtpSender = self.addTrack(pluginMediaTrack, pluginRTCRtpTransceiverId, pluginRTCRtpReceiverId, pluginRTCRtpSenderId, [streamId])
				streamAdded = streamAdded && (pluginRTCRtpSender != nil)
			}

			return streamAdded;

		} else {
			self.rtcPeerConnection.add(pluginMediaStream.rtcMediaStream)
		}

		return true
	}

	func removeStream(_ pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		if (IsUnifiedPlan()) {
			var trackIdsToRemove: [String] = []
			for (_, pluginMediaStreamTrack) in pluginMediaStream.audioTracks {
				trackIdsToRemove.append(pluginMediaStreamTrack.rtcMediaStreamTrack.trackId)
			}
			for (_, pluginMediaStreamTrack) in pluginMediaStream.videoTracks {
				trackIdsToRemove.append(pluginMediaStreamTrack.rtcMediaStreamTrack.trackId)
			}

			for trackId in trackIdsToRemove {
				for (_, pluginRTCRtpSender) in self.pluginRTCRtpSenders {
					if pluginRTCRtpSender.rtpSender.track?.trackId == trackId {
						self.removeTrack(pluginRTCRtpSender)
						break
					}
				}
			}
		} else {
			self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
		}
	}

	func IsUnifiedPlan() -> Bool {
		return rtcPeerConnection.configuration.sdpSemantics == RTCSdpSemantics.unifiedPlan;
	}

	func addTrack(
		_ pluginMediaTrack: PluginMediaStreamTrack,
		_ pluginRTCRtpTransceiverId: Int,
		_ pluginRTCRtpReceiverId: Int,
		_ pluginRTCRtpSenderId: Int,
		_ streamIds: [String]
	) -> PluginRTCRtpSender? {
		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return nil
		}

		let rtcMediaStreamTrack = pluginMediaTrack.rtcMediaStreamTrack;
		var pluginRTCRtpSender = self.pluginRTCRtpSenders[pluginRTCRtpSenderId];
		NSLog("PluginRTCPeerConnection#addTrack() trackId=%@ rtcId=%d streamIds %@",
				pluginMediaTrack.id, pluginRTCRtpSenderId, streamIds);
		if (pluginRTCRtpSender == nil) {
			let rtcRtpSender: RTCRtpSender? = self.rtcPeerConnection.add(rtcMediaStreamTrack, streamIds: streamIds)
			if let rtcRtpSender = rtcRtpSender {
				let pluginRTCRtpTransceiver = self.updateTransceivers(rtcRtpSender: rtcRtpSender)
				self.updateTransceiverId(pluginRTCRtpTransceiver!, pluginRTCRtpTransceiverId, pluginRTCRtpReceiverId, pluginRTCRtpSenderId)
				pluginRTCRtpSender = pluginRTCRtpTransceiver!.pluginRTCRtpSender
			} else {
				NSLog("PluginRTCPeerConnection#addTrack() | RTCPeerConnection#add() failed")
			}
		}

		return pluginRTCRtpSender;
	}

	func removeTrack(_ pluginRTCRtpSender: PluginRTCRtpSender) {
		NSLog("PluginRTCPeerConnection#removeTrack()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		self.rtcPeerConnection.removeTrack(pluginRTCRtpSender.rtpSender)
	}

	func addTransceiver(
		with: PluginMediaStreamTrack?,
		of: RTCRtpMediaType?,
		options: NSDictionary?,
		transceiverId: Int,
		senderId: Int,
		receiverId: Int,
		receiverTrackId: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#addTransceiver()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		var pluginRTCRtpTransceiver: PluginRTCRtpTransceiver

		if with != nil {
			pluginRTCRtpTransceiver = PluginRTCRtpTransceiver(
				rtcPeerConnection: self.rtcPeerConnection,
                mediaStreamTrack: with!.rtcMediaStreamTrack,
				options: options,
				transceiverId: transceiverId,
				senderId: senderId,
				receiverId: receiverId
        	)
		} else if of != nil {
			pluginRTCRtpTransceiver = PluginRTCRtpTransceiver(
				rtcPeerConnection: self.rtcPeerConnection,
                mediaType: of!,
				options: options,
				transceiverId: transceiverId,
				senderId: senderId,
				receiverId: receiverId
        	)
		} else {
			NSLog("PluginRTCPeerConnection#addTransceiver() | error: no valid track or type")
			return
		}

		// NOTE: Creates native track in case it's not already existing.
        self.getPluginMediaStreamTrack(pluginRTCRtpTransceiver.rtcRtpTransceiver!.receiver.track, trackId: receiverTrackId)

		self.updateTransceivers(pluginRTCRtpTransceiver: pluginRTCRtpTransceiver)

		let response: NSDictionary = [
			"transceivers": self.getTransceiversJSON()
		]

		callback(response)
	}
	
	func createIdFor(collection: [Int : Any]) -> Int {
		var newId: Int
		repeat {
			newId = Int.random(in: 10000..<100000)
		} while (collection[newId] != nil)
		return newId
	}

	func updateTransceiverId(
		_ pluginRTCRtpTransceiver: PluginRTCRtpTransceiver,
		_ pluginRTCRtpTransceiverId: Int,
		_ pluginRTCRtpReceiverId: Int,
		_ pluginRTCRtpSenderId: Int
	) {
		self.pluginRTCRtpTransceivers.removeValue(forKey: pluginRTCRtpTransceiver.id)
		pluginRTCRtpTransceiver.id = pluginRTCRtpTransceiverId
		self.pluginRTCRtpTransceivers[pluginRTCRtpTransceiverId] = pluginRTCRtpTransceiver

		self.pluginRTCRtpReceivers.removeValue(forKey: pluginRTCRtpTransceiver.pluginRTCRtpReceiver!.id)
		pluginRTCRtpTransceiver.pluginRTCRtpReceiver!.id = pluginRTCRtpReceiverId
		self.pluginRTCRtpReceivers[pluginRTCRtpReceiverId] = pluginRTCRtpTransceiver.pluginRTCRtpReceiver

		self.pluginRTCRtpSenders.removeValue(forKey: pluginRTCRtpTransceiver.pluginRTCRtpSender!.id)
		pluginRTCRtpTransceiver.pluginRTCRtpSender!.id = pluginRTCRtpSenderId
		self.pluginRTCRtpSenders[pluginRTCRtpSenderId] = pluginRTCRtpTransceiver.pluginRTCRtpSender
	}

	func updateTransceivers(pluginRTCRtpTransceiver: PluginRTCRtpTransceiver) {
		self.pluginRTCRtpTransceivers[pluginRTCRtpTransceiver.id] = pluginRTCRtpTransceiver
		if pluginRTCRtpTransceiver.pluginRTCRtpSender != nil {
			self.pluginRTCRtpSenders[pluginRTCRtpTransceiver.pluginRTCRtpSender!.id] = pluginRTCRtpTransceiver.pluginRTCRtpSender
		}
		if pluginRTCRtpTransceiver.pluginRTCRtpReceiver != nil {
			self.pluginRTCRtpReceivers[pluginRTCRtpTransceiver.pluginRTCRtpReceiver!.id] = pluginRTCRtpTransceiver.pluginRTCRtpReceiver
		}
	}

	func updateTransceivers(rtcRtpSender: RTCRtpSender) -> PluginRTCRtpTransceiver? {
		for rtcRtpTransceiver in self.rtcPeerConnection.transceivers {
			if rtcRtpTransceiver.sender == rtcRtpSender || rtcRtpTransceiver.sender.senderId == rtcRtpSender.senderId {
				return self.updateTransceivers(rtcRtpTransceiver: rtcRtpTransceiver)
			}
		}
		// NOTE: should not happen
		return nil
	}

	func updateTransceivers(rtcRtpTransceiver: RTCRtpTransceiver) -> PluginRTCRtpTransceiver {
		var senderReceiverToTransceiver: [String:PluginRTCRtpTransceiver] = [:]
		for (_, pluginRTCRtpTransceiver) in self.pluginRTCRtpTransceivers {
			// NOTE: this test should be enough
			if pluginRTCRtpTransceiver.rtcRtpTransceiver == rtcRtpTransceiver {
				return pluginRTCRtpTransceiver
			}
			let senderReceiverKey = pluginRTCRtpTransceiver.rtcRtpTransceiver!.sender.senderId + "::" + pluginRTCRtpTransceiver.rtcRtpTransceiver!.receiver.receiverId
			senderReceiverToTransceiver[senderReceiverKey] = pluginRTCRtpTransceiver
		}

		// test by senderId and receiverId
		let key = rtcRtpTransceiver.sender.senderId + "::" + rtcRtpTransceiver.receiver.receiverId
		let existingPluginRTCRtpTransceiver = senderReceiverToTransceiver[key]
		if existingPluginRTCRtpTransceiver != nil {
			return existingPluginRTCRtpTransceiver!
		}

		// new transceiver found
		let pluginRTCRtpTransceiver = PluginRTCRtpTransceiver(rtcRtpTransceiver)
		self.updateTransceivers(pluginRTCRtpTransceiver: pluginRTCRtpTransceiver)
		NSLog("PluginRTCPeerConnection#updateTransceivers() | New transceiver created id=\(pluginRTCRtpTransceiver.id)")
		return pluginRTCRtpTransceiver
	}

	func createDataChannel(
		_ dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
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

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let pluginRTCDTMFSender = PluginRTCDTMFSender(
			rtcPeerConnection: self.rtcPeerConnection,
			track: track.rtcMediaStreamTrack,
			streamId: String(dsId), //TODO
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
//		NSLog("PluginRTCPeerConnection#getStats()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		self.rtcPeerConnection.stats(for: pluginMediaStreamTrack?.rtcMediaStreamTrack, statsOutputLevel: RTCStatsOutputLevel.standard, completionHandler: { (stats: [RTCLegacyStatsReport]) in
			var data: [[String:Any]] = []
			for i in 0 ..< stats.count {
				let report: RTCLegacyStatsReport = stats[i]
				data.append([
					"reportId" : report.reportId,
					"type" : report.type,
					"timestamp" : report.timestamp,
					"values" : report.values
				])
			}
//			NSLog("Stats:\n %@", data)
			callback(data)
		})
	}

	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		for (_, pluginMediaStream) in self.pluginMediaStreams {
			self.eventListenerForRemoveStream(pluginMediaStream)
		}

		for (_, pluginMediaTrack) in self.pluginMediaTracks {
			self.eventListenerForRemoveTrack(pluginMediaTrack)
		}

		self.pluginMediaTracks = [:];
		self.pluginMediaStreams = [:];

		self.rtcPeerConnection.close()
	}

	func RTCDataChannel_sendString(
		_ dcId: Int,
		data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
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

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
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

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
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
		duration: Double,
		interToneGap: Double
	) {
		NSLog("PluginRTCPeerConnection#RTCDTMFSender_insertDTMF()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let pluginRTCDTMFSender = self.pluginRTCDTMFSenders[dsId]
		if pluginRTCDTMFSender == nil {
			return
		}

		pluginRTCDTMFSender!.insertDTMF(tones, duration: duration as TimeInterval, interToneGap: interToneGap as TimeInterval)
	}

	/**
	 * Methods inherited from RTCPeerConnectionDelegate.
	 */

	private func getPluginMediaStream(_ stream: RTCMediaStream?) -> PluginMediaStream? {

		if (stream == nil) {
			return nil;
		}

		var currentMediaStream : PluginMediaStream? = nil;

		for (_, pluginMediaStream) in self.pluginMediaStreams {
			if (pluginMediaStream.rtcMediaStream.streamId == stream!.streamId) {
				currentMediaStream = pluginMediaStream;
				break;
			}
		}

		if (currentMediaStream == nil) {

			currentMediaStream = PluginMediaStream(rtcMediaStream: stream!)

			currentMediaStream!.run()

			// Let the plugin store it in its dictionary.
			self.pluginMediaStreams[currentMediaStream!.id] = currentMediaStream;

			// Fixes issue #576
			self.eventListenerForAddStream(currentMediaStream!)
		}

		return currentMediaStream;
	}


	private func getPluginMediaStreamTrack(_ track: RTCMediaStreamTrack?, trackId: String?) -> PluginMediaStreamTrack? {
		if (track == nil) {
			return nil;
		}

		var currentMediaStreamTrack : PluginMediaStreamTrack? = nil;

		for (_, pluginMediaTrack) in self.pluginMediaTracks {
			if (pluginMediaTrack.rtcMediaStreamTrack.trackId == track!.trackId) {
				currentMediaStreamTrack = pluginMediaTrack;
				break;
			}
		}

		if (currentMediaStreamTrack == nil) {

			currentMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track!, trackId: trackId)

			currentMediaStreamTrack!.run()

			// Let the plugin store it in its dictionary.
			self.pluginMediaTracks[currentMediaStreamTrack!.id] = currentMediaStreamTrack;

			// Fixes issue #576
			self.eventListenerForAddTrack(currentMediaStreamTrack!)
		}

		return currentMediaStreamTrack;
	}

	func getTransceiversJSON() -> [NSDictionary] {
        if (!IsUnifiedPlan()) {
          NSLog("PluginRTCPeerConnection#getTransceiversJSON() | transceiers is not available when using plan-b")
          return [];
        }
        
		return self.rtcPeerConnection.transceivers.map({ (transceiver: RTCRtpTransceiver) -> NSDictionary in
//			let receiverTrack = self.getPluginMediaStreamTrack(transceiver.receiver.track, trackId: nil);
//			let senderTrack = self.getPluginMediaStreamTrack(transceiver.sender.track, trackId: nil);
			let transceiverHolder = self.updateTransceivers(rtcRtpTransceiver: transceiver)
			return transceiverHolder.getJSON()
		})
	}

	/** Called when media is received on a new stream from remote peer. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = getPluginMediaStream(stream);

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener([
			"type": "addstream",
			"streamId": pluginMediaStream!.id,
			"stream": pluginMediaStream!.getJSON(),
			"transceivers": self.getTransceiversJSON()
		])
	}

	/** Called when a remote peer closes a stream. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		let pluginMediaStream = getPluginMediaStream(stream);

		self.eventListenerForRemoveStream(pluginMediaStream!)

		// Let the plugin remove it from its dictionary.
		pluginMediaStreams[pluginMediaStream!.id] = nil;

		self.eventListener([
			"type": "removestream",
			"streamId": pluginMediaStream!.id,
			"transceivers": self.getTransceiversJSON()
		])
	}

	/** New track as been added. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams:[RTCMediaStream]) {

		NSLog("PluginRTCPeerConnection | ontrack")

		let pluginMediaTrack = getPluginMediaStreamTrack(rtpReceiver.track, trackId: nil);

		// Add stream only if available in case of Unified-Plan of track event without stream
		// TODO investigate why no stream sometimes with Unified-Plan and confirm that expexted behavior.

		if (streams.isEmpty) {
			self.eventListener([
				"type": "track",
				"track": pluginMediaTrack!.getJSON(),
				"transceivers": self.getTransceiversJSON()
			])
		} else {
			let pluginMediaStream = getPluginMediaStream(streams[0]);

			// Check if pluginMediaStream had already the new track, otherwise add new track
			if (pluginMediaStream!.hasTrack(pluginMediaTrack!) == false) {
				pluginMediaStream!.addTrack(pluginMediaTrack!);
			}

			self.eventListener([
				"type": "track",
				"track": pluginMediaTrack!.getJSON(),
				"streamId": pluginMediaStream!.id,
				"stream": pluginMediaStream!.getJSON(),
				"transceivers": self.getTransceiversJSON()
			])
		}
	}

	/** Called when the SignalingState changed. */

	// TODO: remove on M75
	// This was already fixed in M-75, but note that "Issue 740501: RTCPeerConnection.onnegotiationneeded can sometimes fire multiple times in a row" was a prerequisite of Perfect Negotiation as well.
	// https://stackoverflow.com/questions/48963787/failed-to-set-local-answer-sdp-called-in-wrong-state-kstable
	// https://bugs.chromium.org/p/chromium/issues/detail?id=740501
	// https://bugs.chromium.org/p/chromium/issues/detail?id=980872
	var isNegotiating = false;

	func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
		let state_str = PluginRTCTypes.signalingStates[stateChanged.rawValue] as String?

		NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:%@]", String(describing: state_str))

		isNegotiating = (state_str != "stable")

		self.eventListener([
			"type": "signalingstatechange",
			"signalingState": state_str!
		])
	}

	/** Called when negotiation is needed, for example ICE has restarted. */
	func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		if (!IsUnifiedPlan() && isNegotiating) {
		  NSLog("PluginRTCPeerConnection#addStream() | signalingState is stable skip nested negotiations when using plan-b")
		  return;
		}

		self.eventListener([
			"type": "negotiationneeded"
		])
	}

	/** Called any time the IceConnectionState changes. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue]

		NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "iceconnectionstatechange",
			"iceConnectionState": state_str as Any
		])
	}

	/** Called any time the IceGatheringState changes. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
		let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue]

		NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "icegatheringstatechange",
			"iceGatheringState": state_str as Any
		])

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		// Emit an empty candidate if iceGatheringState is "complete".
		if newState.rawValue == RTCIceGatheringState.complete.rawValue && self.rtcPeerConnection.localDescription != nil {
			self.eventListener([
				"type": "icecandidate",
				// NOTE: Cannot set null as value.
				"candidate": false,
				"localDescription": [
					"type": RTCSessionDescription.string(for: self.rtcPeerConnection.localDescription!.type),
					"sdp": self.rtcPeerConnection.localDescription!.sdp
				] as [String : Any]
			])
		}
	}

	/** New ice candidate has been found. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
		NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:%@, sdpMLineIndex:%@, candidate:%@]",
			  String(candidate.sdpMid!), String(candidate.sdpMLineIndex), String(candidate.sdp))

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		self.eventListener([
			"type": "icecandidate",
			"candidate": [
				"sdpMid": candidate.sdpMid as Any,
				"sdpMLineIndex": candidate.sdpMLineIndex,
				"candidate": candidate.sdp
			],
			"localDescription": [
				"type": RTCSessionDescription.string(for: self.rtcPeerConnection.localDescription!.type),
				"sdp": self.rtcPeerConnection.localDescription!.sdp
			] as [String : Any]
		])
	}

	/** Called when a group of local Ice candidates have been removed. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
		NSLog("PluginRTCPeerConnection | removeicecandidates")
	}

	/** New data channel has been opened. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didOpen rtcDataChannel: RTCDataChannel) {
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
				"maxPacketLifeTime": rtcDataChannel.maxPacketLifeTime,
				"maxRetransmits": rtcDataChannel.maxRetransmits,
				"protocol": rtcDataChannel.`protocol`,
				"negotiated": rtcDataChannel.isNegotiated,
				"id": rtcDataChannel.channelId,
				"readyState": PluginRTCTypes.dataChannelStates[rtcDataChannel.readyState.rawValue] as Any,
				"bufferedAmount": rtcDataChannel.bufferedAmount
			]
		])
	}
    
    // TODO: Is this event required at all?
    /* Called when transceier will start receiving data. */
    /* func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        NSLog("PluginRTCPeerConnection | didStartReceivingOn")
        
        // NOTE: Is this a new transceiver or was it created already?
        var existingTransceiver: PluginRTCRtpTransceiver? = nil
        
		// TODO: Is it correct reusing transceiver instance with same mid?
        for (_, pluginTransceiver) in pluginRTCRtpTransceivers {
            if (transceiver.mid == pluginTransceiver.rtcRtpTransceiver!.mid) {
                existingTransceiver = pluginTransceiver
                break
            }
        }
        
        if (existingTransceiver == nil) {
            NSLog("PluginRTCPeerConnection | Info: No existing transceiver matching mid: %@", transceiver.mid)

			let tcId = PluginUtils.randomInt(10000, max: 99999)
			let pluginRTCRtpTransceiver = PluginRTCRtpTransceiver(transceiver)

			self.pluginRTCRtpTransceivers[tcId] = pluginRTCRtpTransceiver

			var currentDirection = RTCRtpTransceiverDirection.inactive
            transceiver.currentDirection(&currentDirection)

			self.eventListener([
				"type": "transceiver",
				"transceiver": [
                    "tcId": tcId,
                    "mid": transceiver.mid,
					"currentDirection": PluginRTCRtpTransceiver.directionToString(currentDirection),
                	"direction": PluginRTCRtpTransceiver.directionToString(transceiver.direction),
                	"stopped": transceiver.isStopped
				]
			])
        } else {
			// TODO: Can this situation happen?
            NSLog("PluginRTCPeerConnection | Info: Found existing transceiver matching mid: %@", transceiver.mid)
        }
    } */
}
