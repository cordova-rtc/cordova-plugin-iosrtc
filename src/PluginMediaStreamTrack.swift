import Foundation


class PluginMediaStreamTrack : NSObject, RTCMediaStreamTrackDelegate {
	var rtcMediaStreamTrack: RTCMediaStreamTrack
	var id: String
	var kind: String
	var eventListener: ((data: NSDictionary) -> Void)?
	var eventListenerForEnded: (() -> Void)?
	var lostStates = Array<String>()


	init(rtcMediaStreamTrack: RTCMediaStreamTrack) {
		NSLog("PluginMediaStreamTrack#init()")

		self.rtcMediaStreamTrack = rtcMediaStreamTrack
		self.id = rtcMediaStreamTrack.label  // NOTE: No "id" property provided.
		self.kind = rtcMediaStreamTrack.kind
	}


	deinit {
		NSLog("PluginMediaStreamTrack#deinit()")
	}


	func run() {
		NSLog("PluginMediaStreamTrack#run() [kind:%@, id:%@]", String(self.kind), String(self.id))

		self.rtcMediaStreamTrack.delegate = self
	}


	func getJSON() -> NSDictionary {
		return [
			"id": self.id,
			"kind": self.kind,
			"label": self.rtcMediaStreamTrack.label,
			"enabled": self.rtcMediaStreamTrack.isEnabled() ? true : false,
			"readyState": PluginRTCTypes.mediaStreamTrackStates[self.rtcMediaStreamTrack.state().rawValue] as String!
		]
	}


	func setListener(
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForEnded: () -> Void
	) {
		NSLog("PluginMediaStreamTrack#setListener() [kind:%@, id:%@]", String(self.kind), String(self.id))

		self.eventListener = eventListener
		self.eventListenerForEnded = eventListenerForEnded

		for readyState in self.lostStates {
			self.eventListener!(data: [
				"type": "statechange",
				"readyState": readyState,
				"enabled": self.rtcMediaStreamTrack.isEnabled() ? true : false
			])

			if readyState == "ended" {
				self.eventListenerForEnded!()
			}
		}
		self.lostStates.removeAll()
	}


	func setEnabled(value: Bool) {
		NSLog("PluginMediaStreamTrack#setEnabled() [kind:%@, id:%@, value:%@]",
			String(self.kind), String(self.id), String(value))

		self.rtcMediaStreamTrack.setEnabled(value)
	}


	// TODO: No way to stop the track.
	// Check https://github.com/eface2face/cordova-plugin-iosrtc/issues/140
	func stop() {
		NSLog("PluginMediaStreamTrack#stop() [kind:%@, id:%@]", String(self.kind), String(self.id))

		NSLog("PluginMediaStreamTrack#stop() | stop() not implemented (see: https://github.com/eface2face/cordova-plugin-iosrtc/issues/140")

		// NOTE: There is no setState() anymore
		// self.rtcMediaStreamTrack.setState(RTCTrackStateEnded)

		// Let's try setEnabled(false), but it also fails.
		self.rtcMediaStreamTrack.setEnabled(false)
	}


	/**
	 * Methods inherited from RTCMediaStreamTrackDelegate.
	 */


	func mediaStreamTrackDidChange(rtcMediaStreamTrack: RTCMediaStreamTrack!) {
		let state_str = PluginRTCTypes.mediaStreamTrackStates[self.rtcMediaStreamTrack.state().rawValue] as String!

		NSLog("PluginMediaStreamTrack | state changed [kind:%@, id:%@, state:%@, enabled:%@]",
			String(self.kind), String(self.id), String(state_str), String(self.rtcMediaStreamTrack.isEnabled()))

		if self.eventListener != nil {
			self.eventListener!(data: [
				"type": "statechange",
				"readyState": state_str,
				"enabled": self.rtcMediaStreamTrack.isEnabled() ? true : false
			])

			if self.rtcMediaStreamTrack.state().rawValue == RTCTrackStateEnded.rawValue {
				self.eventListenerForEnded!()
			}
		} else {
			// It may happen that the eventListener is not yet set, so store the lost states.
			self.lostStates.append(state_str)
		}
	}
}
