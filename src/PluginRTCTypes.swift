struct PluginRTCTypes {
	static let signalingStates = [
		RTCSignalingState.stable.rawValue:             "stable",
		RTCSignalingState.haveLocalOffer.rawValue:     "have-local-offer",
		RTCSignalingState.haveLocalPrAnswer.rawValue:  "have-local-pranswer",
		RTCSignalingState.haveRemoteOffer.rawValue:    "have-remote-offer",
		RTCSignalingState.haveRemotePrAnswer.rawValue: "have-remote-pranswer",
		RTCSignalingState.closed.rawValue:             "closed"
	]

	static let iceGatheringStates = [
		RTCIceGatheringState.new.rawValue:            "new",
		RTCIceGatheringState.gathering.rawValue:      "gathering",
		RTCIceGatheringState.complete.rawValue:       "complete"
	]

	static let iceConnectionStates = [
		RTCIceConnectionState.new.rawValue:            "new",
		RTCIceConnectionState.checking.rawValue:       "checking",
		RTCIceConnectionState.connected.rawValue:      "connected",
		RTCIceConnectionState.completed.rawValue:      "completed",
		RTCIceConnectionState.failed.rawValue:         "failed",
		RTCIceConnectionState.disconnected.rawValue:   "disconnected",
		RTCIceConnectionState.closed.rawValue:         "closed"
	]

	static let dataChannelStates = [
		RTCDataChannelState.connecting.rawValue: "connecting",
		RTCDataChannelState.open.rawValue:       "open",
		RTCDataChannelState.closing.rawValue:    "closing",
		RTCDataChannelState.closed.rawValue:     "closed"
	]

	static let mediaStreamTrackStates = [
		RTCMediaStreamTrackState.live.rawValue:		"live",
		RTCMediaStreamTrackState.ended.rawValue:	"ended"
	]

}
