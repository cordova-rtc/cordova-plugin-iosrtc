import Foundation


class PluginRTCDTMFSender : NSObject, RTCDTMFSenderDelegate {
	var rtcDTMFSender: RTCDTMFSender?
	var eventListener: ((_ data: NSDictionary) -> Void)?


	/**
	* Constructor for pc.createDTMFSender().
	*/
	init(
		rtcPeerConnection: RTCPeerConnection,
		track: RTCMediaStreamTrack,
		eventListener: @escaping (_ data: NSDictionary) -> Void
		) {
		NSLog("PluginRTCDTMFSender#init()")

		self.eventListener = eventListener
		self.rtcDTMFSender = rtcPeerConnection.createDTMFSender(for: track as? RTCAudioTrack)

		if self.rtcDTMFSender == nil {
			NSLog("PluginRTCDTMFSender#init() | rtcPeerConnection.createDTMFSenderForTrack() failed")
			return
		}
	}


	deinit {
		NSLog("PluginRTCDTMFSender#deinit()")
	}


	func run() {
		NSLog("PluginRTCDTMFSender#run()")

		self.rtcDTMFSender!.delegate = self
	}


	func insertDTMF(_ tones: String, duration: Int, interToneGap: Int) {
		NSLog("PluginRTCDTMFSender#insertDTMF()")

		let result = self.rtcDTMFSender!.insertDTMF(tones, withDuration: duration, andInterToneGap: interToneGap)
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
