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

	var onCreateLocalDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateLocalDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onCreateRemoteDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateRemoteDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onGetStatsCallback: ((_ array: NSArray) -> Void)!

	var pluginMediaStreams: [String : PluginMediaStream]! = [:]
	var trackIdsToSenders: [String : RTCRtpSender] = [:]

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
				"sdp": rtcSessionDescription.sdp
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
				"sdp": rtcSessionDescription.sdp
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
			let data = [
				"type": RTCSessionDescription.string(for: self.rtcPeerConnection.localDescription!.type),
				"sdp": self.rtcPeerConnection.localDescription!.sdp
			] as [String : Any]

			callback(data as NSDictionary)
		}

		self.onSetDescriptionFailureCallback = { (error: Error) -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}

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
				"sdp": self.rtcPeerConnection.remoteDescription!.sdp
			]

			callback(data as NSDictionary)
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
				streamAdded = self.addTrack(pluginMediaTrack, [streamId]) && streamAdded;
			}

			for (_, pluginMediaTrack) in pluginMediaStream.videoTracks {
				streamAdded = self.addTrack(pluginMediaTrack, [streamId]) && streamAdded;
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

			for (_, pluginMediaStream) in pluginMediaStream.audioTracks {
				self.removeTrack(pluginMediaStream)
			}

			for (_, pluginMediaStream) in pluginMediaStream.videoTracks {
				self.removeTrack(pluginMediaStream)
			}

		} else {
			self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
		}
	}

	func IsUnifiedPlan() -> Bool {
		return rtcPeerConnection.configuration.sdpSemantics == RTCSdpSemantics.unifiedPlan;
	}

	func addTrack(_ pluginMediaTrack: PluginMediaStreamTrack, _ streamIds: [String]) -> Bool {
		NSLog("PluginRTCPeerConnection#addTrack()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return false
		}

		let rtcMediaStreamTrack = pluginMediaTrack.rtcMediaStreamTrack;
		var rtcSender = trackIdsToSenders[rtcMediaStreamTrack.trackId];
		if (rtcSender == nil) {
			rtcSender = self.rtcPeerConnection.add(rtcMediaStreamTrack, streamIds: streamIds)
			trackIdsToSenders[rtcMediaStreamTrack.trackId] = rtcSender;
			return true;
		}

		return false;
	}

	func removeTrack(_ pluginMediaTrack: PluginMediaStreamTrack) {
		NSLog("PluginRTCPeerConnection#removeTrack()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		let rtcMediaStreamTrack = pluginMediaTrack.rtcMediaStreamTrack;
		let rtcSender = trackIdsToSenders[rtcMediaStreamTrack.trackId];

		if (rtcSender != nil) {
			self.rtcPeerConnection.removeTrack(rtcSender!)
			trackIdsToSenders[rtcMediaStreamTrack.trackId] = nil
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
		NSLog("PluginRTCPeerConnection#getStats()")

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
			NSLog("Stats:\n %@", data)
			callback(data)
		})
	}

	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState == RTCSignalingState.closed {
			return
		}

		for (_, pluginMediaStream) in pluginMediaStreams {
			self.eventListenerForRemoveStream(pluginMediaStream.id)
		}

		pluginMediaStreams = [:];

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

	private func getPluginMediaStream(stream: RTCMediaStream?) -> PluginMediaStream? {

		if (stream == nil) {
			return nil;
		}

		var currentPluginMediaStream : PluginMediaStream? = nil;

		for (_, pluginMediaStream) in pluginMediaStreams {
			if (pluginMediaStream.rtcMediaStream == stream) {
				currentPluginMediaStream = pluginMediaStream;
				break;
			}
		}

		if (currentPluginMediaStream == nil) {

			currentPluginMediaStream = PluginMediaStream(rtcMediaStream: stream!)

			currentPluginMediaStream!.run()

			// Let the plugin store it in its dictionary.
			pluginMediaStreams[currentPluginMediaStream!.id] = currentPluginMediaStream;
		}

		return currentPluginMediaStream;
	}

	/** Called when media is received on a new stream from remote peer. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = getPluginMediaStream(stream: stream);

		self.eventListenerForAddStream(pluginMediaStream!)

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener([
			"type": "addstream",
			"streamId": pluginMediaStream!.id,
			"stream": pluginMediaStream!.getJSON()
		])
	}

	/** Called when a remote peer closes a stream. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		let pluginMediaStream = getPluginMediaStream(stream: stream);

		self.eventListenerForRemoveStream(pluginMediaStream!.id)

		// Let the plugin remove it from its dictionary.
		pluginMediaStreams[pluginMediaStream!.id] = nil;

		self.eventListener([
			"type": "removestream",
			"streamId": pluginMediaStream!.id
		])
	}

	/** New track as been added. */
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams:[RTCMediaStream]) {

		NSLog("PluginRTCPeerConnection | onaddtrack")

		let pluginMediaTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: rtpReceiver.track!)

		// Add stream only if available in case of Unified-Plan of track event without stream
		// TODO investigate why no stream sometimes with Unified-Plan and confirm that expexted behavior.

		if (streams.isEmpty) {
			self.eventListener([
				"type": "track",
				"track": pluginMediaTrack.getJSON(),
			])
		} else {
			let pluginMediaStream = getPluginMediaStream(stream: streams[0]);

			self.eventListener([
				"type": "track",
				"track": pluginMediaTrack.getJSON(),
				"streamId": pluginMediaStream!.id,
				"stream": pluginMediaStream!.getJSON()
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
}
