import Foundation

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
	return l < r
  case (nil, _?):
	return true
  default:
	return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
	return l > r
  default:
	return rhs < lhs
  }
}

class PluginRTCDataChannel : NSObject, RTCDataChannelDelegate {
	var rtcDataChannel: RTCDataChannel?
	var eventListener: ((_ data: NSDictionary) -> Void)?
	var eventListenerForBinaryMessage: ((_ data: Data) -> Void)?
	var lostStates = Array<String>()
	var lostMessages = Array<RTCDataBuffer>()

	/**
	 * Constructor for pc.createDataChannel().
	 */
	init(
		rtcPeerConnection: RTCPeerConnection,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCDataChannel#init()")

		self.eventListener = eventListener
		self.eventListenerForBinaryMessage = eventListenerForBinaryMessage

		let rtcDataChannelInit = RTCDataChannelConfiguration.init()

		if options?.object(forKey: "ordered") != nil {
			rtcDataChannelInit.isOrdered = options!.object(forKey: "ordered") as! Bool
		}

		if options?.object(forKey: "maxPacketLifeTime") != nil {
			// TODO: rtcDataChannel.maxRetransmitTime always reports 0.
			rtcDataChannelInit.maxRetransmitTimeMs = options!.object(forKey: "maxPacketLifeTime") as! Int
		}

		if options?.object(forKey: "maxRetransmits") != nil {
			rtcDataChannelInit.maxRetransmits = options!.object(forKey: "maxRetransmits") as! Int32
		}

		// TODO: error: expected member name following '.'
		//   https://code.google.com/p/webrtc/issues/detail?id=4614
		// if options?.objectForKey("protocol") != nil {
			// rtcDataChannelInit.protocol = options!.objectForKey("protocol") as! String
		// }
		if options?.object(forKey: "protocol") != nil {
			rtcDataChannelInit.`protocol` = options!.object(forKey: "protocol") as! String
		}

		if options?.object(forKey: "negotiated") != nil {
			rtcDataChannelInit.isNegotiated = options!.object(forKey: "negotiated") as! Bool
		}

		if options?.object(forKey: "id") != nil {
			rtcDataChannelInit.channelId = options!.object(forKey: "id") as! Int32
		}

		self.rtcDataChannel = rtcPeerConnection.dataChannel(forLabel: label, configuration: rtcDataChannelInit)

		if self.rtcDataChannel == nil {
			NSLog("PluginRTCDataChannel#init() | rtcPeerConnection.createDataChannelWithLabel() failed")
			return
		}

		// Report definitive data to update the JS instance.
		self.eventListener!([
			"type": "new",
			"channel": [
				"ordered": self.rtcDataChannel!.isOrdered,
				"maxPacketLifeTime": self.rtcDataChannel!.maxPacketLifeTime,
				"maxRetransmits": self.rtcDataChannel!.maxRetransmits,
				"protocol": self.rtcDataChannel!.`protocol`,
				"negotiated": self.rtcDataChannel!.isNegotiated,
				"id": self.rtcDataChannel!.channelId,
				"readyState": PluginRTCDataChannel.stateToString(state: self.rtcDataChannel!.readyState),
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

		//if data channel is created after there is a connection,
		// we need to dispatch its current state.
		if (self.rtcDataChannel?.readyState != RTCDataChannelState.connecting) {
			dataChannelDidChangeState(self.rtcDataChannel!);
		}
	}

	func setListener(
		_ eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCDataChannel#setListener()")

		self.eventListener = eventListener
		self.eventListenerForBinaryMessage = eventListenerForBinaryMessage

		for readyState in self.lostStates {
			self.eventListener!([
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
		_ data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCDataChannel#sendString()")

		let buffer = RTCDataBuffer(
			data: (data.data(using: String.Encoding.utf8))!,
			isBinary: false
		)

		let result = self.rtcDataChannel!.sendData(buffer)
		if !result {
			NSLog("PluginRTCDataChannel#sendString() | RTCDataChannel#sendData() failed")
		}
	}

	func sendBinary(
		_ data: Data,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCDataChannel#sendBinary()")

		let buffer = RTCDataBuffer(
			data: data,
			isBinary: true
		)

		let result = self.rtcDataChannel!.sendData(buffer)
		if !result {
			NSLog("PluginRTCDataChannel#sendBinary() | RTCDataChannel#sendData() failed")
		}
	}

	func close() {
		NSLog("PluginRTCDataChannel#close()")

		self.rtcDataChannel!.close()
	}
	
	static func stateToString(state: RTCDataChannelState) -> String {
		switch state {
		case RTCDataChannelState.connecting:
			return "connecting"
		case RTCDataChannelState.open:
			return "open"
		case RTCDataChannelState.closing:
			return "closing"
		case RTCDataChannelState.closed:
			return "closed"
		}
	}

	func getState() -> String {
		return PluginRTCDataChannel.stateToString(state: self.rtcDataChannel!.readyState)
	}

	/**
	 * Methods inherited from RTCDataChannelDelegate.
	 */

	/** The data channel state changed. */
	func dataChannelDidChangeState(_ channel: RTCDataChannel) {
		let state_str = self.getState()

		NSLog("PluginRTCDataChannel | state changed [state:%@]", String(describing: state_str))

		if self.eventListener != nil {
			self.eventListener!([
				"type": "statechange",
				"readyState": state_str
			])
		} else {
			// It may happen that the eventListener is not yet set, so store the lost states.
			self.lostStates.append(state_str)
		}
	}

	/** The data channel successfully received a data buffer. */
	func dataChannel(_ channel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		if !buffer.isBinary {
			NSLog("PluginRTCDataChannel | utf8 message received")

			if self.eventListener != nil {
				self.emitReceivedMessage(buffer)
			} else {
				// It may happen that the eventListener is not yet set, so store the lost messages.
				self.lostMessages.append(buffer)
			}
		} else {
			NSLog("PluginRTCDataChannel | binary message received")

			if self.eventListenerForBinaryMessage != nil {
				self.emitReceivedMessage(buffer)
			} else {
				// It may happen that the eventListener is not yet set, so store the lost messages.
				self.lostMessages.append(buffer)
			}
		}
	}

	/** The data channel's |bufferedAmount| changed. */
	func dataChannel(_ channel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
		NSLog("PluginRTCDataChannel | didChangeBufferedAmount %d", amount)

		self.eventListener!([
			"type": "bufferedamount",
			"bufferedAmount": amount
			])

	}

	func emitReceivedMessage(_ buffer: RTCDataBuffer) {
		if !buffer.isBinary {
			let message = NSString(
				data: buffer.data,
				encoding: String.Encoding.utf8.rawValue
			)

			self.eventListener!([
				"type": "message",
				"message": message! as String
			])
		} else {
			self.eventListenerForBinaryMessage!(buffer.data)
		}
	}
}
