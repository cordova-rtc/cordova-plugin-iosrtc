struct PluginRTCTypes {
	static let signalingStates = [
		RTCSignalingStable.rawValue:             "stable",
		RTCSignalingHaveLocalOffer.rawValue:     "have-local-offer",
		RTCSignalingHaveLocalPrAnswer.rawValue:  "have-local-pranswer",
		RTCSignalingHaveRemoteOffer.rawValue:    "have-remote-offer",
		RTCSignalingHaveRemotePrAnswer.rawValue: "have-remote-pranswer",
		RTCSignalingClosed.rawValue:             "closed"
	]

	static let iceGatheringStates = [
		RTCICEGatheringNew.rawValue:            "new",
		RTCICEGatheringGathering.rawValue:      "gathering",
		RTCICEGatheringComplete.rawValue:       "complete"
	]

	static let iceConnectionStates = [
		RTCICEConnectionNew.rawValue:            "new",
		RTCICEConnectionChecking.rawValue:       "checking",
		RTCICEConnectionConnected.rawValue:      "connected",
		RTCICEConnectionCompleted.rawValue:      "completed",
		RTCICEConnectionFailed.rawValue:         "failed",
		RTCICEConnectionDisconnected.rawValue:   "disconnected",
		RTCICEConnectionClosed.rawValue:         "closed"
	]

	static let dataChannelStates = [
		kRTCDataChannelStateConnecting.rawValue: "connecting",
		kRTCDataChannelStateOpen.rawValue:       "open",
		kRTCDataChannelStateClosing.rawValue:    "closing",
		kRTCDataChannelStateClosed.rawValue:     "closed"
	]

	static let mediaStreamTrackStates = [
		RTCTrackStateLive.rawValue:              "live",
		RTCTrackStateEnded.rawValue:             "ended"
	]
}
