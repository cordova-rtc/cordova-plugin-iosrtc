import Foundation


class PluginRTCDataChannel : NSObject, RTCDataChannelDelegate {
	var rtcDataChannel: RTCDataChannel?
	var eventListener: ((data: NSDictionary) -> Void)?
	var eventListenerForBinaryMessage: ((data: NSData) -> Void)?
	var lostStates = Array<String>()
	var lostMessages = Array<RTCDataBuffer>()


	/**
	 * Constructor for pc.createDataChannel().
	 */
	init(
		rtcPeerConnection: RTCPeerConnection,
		label: String,
		options: NSDictionary?,
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: (data: NSData) -> Void
	) {
		NSLog("PluginRTCDataChannel#init()")

		self.eventListener = eventListener
		self.eventListenerForBinaryMessage = eventListenerForBinaryMessage

		let rtcDataChannelInit = RTCDataChannelInit()

		if options?.objectForKey("ordered") != nil {
			rtcDataChannelInit.isOrdered = options!.objectForKey("ordered") as! Bool
		}

		if options?.objectForKey("maxPacketLifeTime") != nil {
			// TODO: rtcDataChannel.maxRetransmitTime always reports 0.
			rtcDataChannelInit.maxRetransmitTimeMs = options!.objectForKey("maxPacketLifeTime") as! Int
		}

		if options?.objectForKey("maxRetransmits") != nil {
			rtcDataChannelInit.maxRetransmits = options!.objectForKey("maxRetransmits") as! Int
		}

		// TODO: error: expected member name following '.'
		//   https://code.google.com/p/webrtc/issues/detail?id=4614
		// if options?.objectForKey("protocol") != nil {
			// rtcDataChannelInit.protocol = options!.objectForKey("protocol") as! String
		// }
		if options?.objectForKey("protocol") != nil {
			rtcDataChannelInit.`protocol` = options!.objectForKey("protocol") as! String
		}

		if options?.objectForKey("negotiated") != nil {
			rtcDataChannelInit.isNegotiated = options!.objectForKey("negotiated") as! Bool
		}

		if options?.objectForKey("id") != nil {
			rtcDataChannelInit.streamId = options!.objectForKey("id") as! Int
		}

		self.rtcDataChannel = rtcPeerConnection.createDataChannelWithLabel(label,
			config: rtcDataChannelInit
		)

		if self.rtcDataChannel == nil {
			NSLog("PluginRTCDataChannel#init() | rtcPeerConnection.createDataChannelWithLabel() failed")
			return
		}

		// Report definitive data to update the JS instance.
		self.eventListener!(data: [
			"type": "new",
			"channel": [
				"ordered": self.rtcDataChannel!.isOrdered,
				"maxPacketLifeTime": self.rtcDataChannel!.maxRetransmitTime,
				"maxRetransmits": self.rtcDataChannel!.maxRetransmits,
				"protocol": self.rtcDataChannel!.`protocol`,
				"negotiated": self.rtcDataChannel!.isNegotiated,
				"id": self.rtcDataChannel!.streamId,
				"readyState": PluginRTCTypes.dataChannelStates[self.rtcDataChannel!.state.rawValue] as String!,
				"bufferedAmount": self.rtcDataChannel!.bufferedAmount
			]
		])
	}


	deinit {
		NSLog("PluginRTCDataChannel#deinit()")
	}


	/**
	 * Constructor for pc.ondatachannel event.
	 */
	init(rtcDataChannel: RTCDataChannel) {
		NSLog("PluginRTCDataChannel#init()")

		self.rtcDataChannel = rtcDataChannel
	}


	func run() {
		NSLog("PluginRTCDataChannel#run()")

		self.rtcDataChannel!.delegate = self
	}


	func setListener(
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: (data: NSData) -> Void
	) {
		NSLog("PluginRTCDataChannel#setListener()")

		self.eventListener = eventListener
		self.eventListenerForBinaryMessage = eventListenerForBinaryMessage

		for readyState in self.lostStates {
			self.eventListener!(data: [
				"type": "statechange",
				"readyState": readyState
			])
		}
		self.lostStates.removeAll()

		for buffer in self.lostMessages {
			self.emitReceivedMessage(buffer)
		}
		self.lostMessages.removeAll()
	}


	func sendString(
		data: String,
		callback: (data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCDataChannel#sendString()")

		let buffer = RTCDataBuffer(
			data: (data.dataUsingEncoding(NSUTF8StringEncoding))!,
			isBinary: false
		)

		let result = self.rtcDataChannel!.sendData(buffer)
		if result == true {
			callback(data: [
				"bufferedAmount": self.rtcDataChannel!.bufferedAmount
			])
		} else {
			NSLog("PluginRTCDataChannel#sendString() | RTCDataChannel#sendData() failed")
		}
	}


	func sendBinary(
		data: NSData,
		callback: (data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCDataChannel#sendBinary()")

		let buffer = RTCDataBuffer(
			data: data,
			isBinary: true
		)

		let result = self.rtcDataChannel!.sendData(buffer)
		if result == true {
			callback(data: [
				"bufferedAmount": self.rtcDataChannel!.bufferedAmount
			])
		} else {
			NSLog("PluginRTCDataChannel#sendBinary() | RTCDataChannel#sendData() failed")
		}
	}


	func close() {
		NSLog("PluginRTCDataChannel#close()")

		self.rtcDataChannel!.close()
	}


	/**
	 * Methods inherited from RTCDataChannelDelegate.
	 */


	func channelDidChangeState(channel: RTCDataChannel!) {
		let state_str = PluginRTCTypes.dataChannelStates[self.rtcDataChannel!.state.rawValue] as String!

		NSLog("PluginRTCDataChannel | state changed [state:%@]", String(state_str))

		if self.eventListener != nil {
			self.eventListener!(data: [
				"type": "statechange",
				"readyState": state_str
			])
		} else {
			// It may happen that the eventListener is not yet set, so store the lost states.
			self.lostStates.append(state_str)
		}
	}


	func channel(channel: RTCDataChannel!, didReceiveMessageWithBuffer buffer: RTCDataBuffer!) {
		if buffer.isBinary == false {
			NSLog("PluginRTCDataChannel | utf8 message received")

			if self.eventListener != nil {
				self.emitReceivedMessage(buffer!)
			} else {
				// It may happen that the eventListener is not yet set, so store the lost messages.
				self.lostMessages.append(buffer!)
			}
		} else {
			NSLog("PluginRTCDataChannel | binary message received")

			if self.eventListenerForBinaryMessage != nil {
				self.emitReceivedMessage(buffer!)
			} else {
				// It may happen that the eventListener is not yet set, so store the lost messages.
				self.lostMessages.append(buffer!)
			}
		}
	}


	func emitReceivedMessage(buffer: RTCDataBuffer) {
		if buffer.isBinary == false {
			let string = NSString(
				data: buffer.data,
				encoding: NSUTF8StringEncoding
			)

			self.eventListener!(data: [
				"type": "message",
				"message": string as! String
			])
		} else {
			self.eventListenerForBinaryMessage!(data: buffer.data)
		}
	}
}
