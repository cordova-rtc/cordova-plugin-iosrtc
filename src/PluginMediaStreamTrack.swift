import Foundation


class PluginMediaStreamTrack : NSObject, RTCMediaStreamTrackDelegate {
	var rtcMediaStreamTrack: RTCMediaStreamTrack
	var id: String
	var kind: String
	var eventListener: ((_ data: NSDictionary) -> Void)?
	var eventListenerForEnded: (() -> Void)?
	var lostStates = Array<String>()


	init(rtcMediaStreamTrack: RTCMediaStreamTrack) {
		NSLog("PluginMediaStreamTrack#init()")

		self.rtcMediaStreamTrack = rtcMediaStreamTrack
		self.id = rtcMediaStreamTrack.trackId
		self.kind = rtcMediaStreamTrack.kind
	}


	deinit {
		NSLog("PluginMediaStreamTrack#deinit()")
	}


	func run() {
		NSLog("PluginMediaStreamTrack#run() [kind:%@, id:%@]", String(self.kind), String(self.id))
	}
	
	func getReadyState() -> String {
		switch self.rtcMediaStreamTrack.readyState  {
		case RTCMediaStreamTrackState.live:
			return "live"
		case RTCMediaStreamTrackState.ended:
			return "ended"
		default:
			return "ended"
		}
		return "ended"
	}

	func getJSON() -> NSDictionary {
		return [
			"id": self.id,
			"kind": self.kind,
			"trackId": self.rtcMediaStreamTrack.trackId,
			"enabled": self.rtcMediaStreamTrack.isEnabled ? true : false,
			"readyState": self.getReadyState()
		]
	}


	func setListener(
		_ eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForEnded: @escaping () -> Void
	) {
		NSLog("PluginMediaStreamTrack#setListener() [kind:%@, id:%@]", String(self.kind), String(self.id))

		self.eventListener = eventListener
		self.eventListenerForEnded = eventListenerForEnded

		for readyState in self.lostStates {
			self.eventListener!([
				"type": "statechange",
				"readyState": readyState,
				"enabled": self.rtcMediaStreamTrack.isEnabled ? true : false
			])

			if readyState == "ended" {
				if(self.eventListenerForEnded != nil) {
					self.eventListenerForEnded!()
				}
			}
		}
		self.lostStates.removeAll()
	}


	func setEnabled(_ value: Bool) {
		NSLog("PluginMediaStreamTrack#setEnabled() [kind:%@, id:%@, value:%@]",
			String(self.kind), String(self.id), String(value))

		self.rtcMediaStreamTrack.isEnabled = value
	}


	// TODO: No way to stop the track.
	// Check https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/140
	func stop() {
		NSLog("PluginMediaStreamTrack#stop() [kind:%@, id:%@]", String(self.kind), String(self.id))

		NSLog("PluginMediaStreamTrack#stop() | stop() not implemented (see: https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/140")

		// Let's try setEnabled(false), but it also fails.
		self.rtcMediaStreamTrack.isEnabled = false
	}


	/**
	 * Methods inherited from RTCMediaStreamTrackDelegate.
	 */


	func mediaStreamTrackDidChange(_ rtcMediaStreamTrack: RTCMediaStreamTrack) {
		let state_str = self.getReadyState()

		NSLog("PluginMediaStreamTrack | state changed [kind:%@, id:%@, state:%@, enabled:%@]",
			String(self.kind), String(self.id), String(describing: state_str), String(self.rtcMediaStreamTrack.isEnabled))

		if self.eventListener != nil {
			self.eventListener!([
				"type": "statechange",
				"readyState": state_str,
				"enabled": self.rtcMediaStreamTrack.isEnabled ? true : false
			])

			if self.rtcMediaStreamTrack.readyState.rawValue == RTCMediaStreamTrackState.ended.rawValue {
				if self.eventListenerForEnded != nil {
					self.eventListenerForEnded!()
				}
			}
		} else {
			// It may happen that the eventListener is not yet set, so store the lost states.
			self.lostStates.append(state_str)
		}
	}
}
