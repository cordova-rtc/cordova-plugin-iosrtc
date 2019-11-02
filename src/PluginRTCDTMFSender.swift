import Foundation


class PluginRTCDTMFSender : NSObject {
	var rtcRtpSender: RTCRtpSender?
	var eventListener: ((_ data: NSDictionary) -> Void)?

	/**
	 * Constructor for pc.createDTMFSender().
	 */
	init(
		rtcPeerConnection: RTCPeerConnection,
		track: RTCMediaStreamTrack,
		streamId: String,
		eventListener: @escaping (_ data: NSDictionary) -> Void
		) {
		NSLog("PluginRTCDTMFSender#init()")

		self.eventListener = eventListener
		
		// TODO check if new rtcRtpSender can be used one Unified-Plan merged
		//let streamIds = [streamId]
		//self.rtcRtpSender = rtcPeerConnection.add(track, streamIds: streamIds);
		self.rtcRtpSender = rtcPeerConnection.senders[0]

		if self.rtcRtpSender == nil {
			NSLog("PluginRTCDTMFSender#init() | rtcPeerConnection.createDTMFSenderForTrack() failed")
			return
		}
	}

	deinit {
		NSLog("PluginRTCDTMFSender#deinit()")
	}

	func run() {
		NSLog("PluginRTCDTMFSender#run()")
	}

	func insertDTMF(_ tones: String, duration: TimeInterval, interToneGap: TimeInterval) {
		NSLog("PluginRTCDTMFSender#insertDTMF()")

		let dtmfSender = self.rtcRtpSender?.dtmfSender
		let durationMs = duration / 100
		let interToneGapMs = interToneGap / 100
		let result = dtmfSender!.insertDtmf(tones, duration: durationMs, interToneGap: interToneGapMs)
		if !result {
			NSLog("PluginRTCDTMFSender#indertDTMF() | RTCDTMFSender#indertDTMF() failed")
		}
	}

	/**
	 * Methods inherited from RTCDTMFSenderDelegate.
	 */
	func toneChange(_ tone: String) {
		NSLog("PluginRTCDTMFSender | tone change [tone:%@]", tone)

		if self.eventListener != nil {
			self.eventListener!([
				"type": "tonechange",
				"tone": tone
			])
		}
	}
}
