struct PluginRTCTypes {
	static let signalingStates = [
		RTCSignalingStable.value:             "stable",
		RTCSignalingHaveLocalOffer.value:     "have-local-offer",
		RTCSignalingHaveLocalPrAnswer.value:  "have-local-pranswer",
		RTCSignalingHaveRemoteOffer.value:    "have-remote-offer",
		RTCSignalingHaveRemotePrAnswer.value: "have-remote-pranswer",
		RTCSignalingClosed.value:             "closed"
	]

	static let iceGatheringStates = [
		RTCICEGatheringNew.value:            "new",
		RTCICEGatheringGathering.value:      "gathering",
		RTCICEGatheringComplete.value:       "complete"
	]

	static let iceConnectionStates = [
		RTCICEConnectionNew.value:            "new",
		RTCICEConnectionChecking.value:       "checking",
		RTCICEConnectionConnected.value:      "connected",
		RTCICEConnectionCompleted.value:      "completed",
		RTCICEConnectionFailed.value:         "failed",
		RTCICEConnectionDisconnected.value:   "disconnected",
		RTCICEConnectionClosed.value:         "closed"
	]

	static let dataChannelStates = [
		kRTCDataChannelStateConnecting.value: "connecting",
		kRTCDataChannelStateOpen.value:       "open",
		kRTCDataChannelStateClosing.value:    "closing",
		kRTCDataChannelStateClosed.value:     "closed"
	]

	static let mediaStreamTrackStates = [
		RTCTrackStateInitializing.value:      "initializing",
		RTCTrackStateLive.value:              "live",
		RTCTrackStateEnded.value:             "ended",
		RTCTrackStateFailed.value:            "failed"
	]
}
