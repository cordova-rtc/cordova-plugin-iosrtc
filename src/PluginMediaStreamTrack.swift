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


	func run() {
		NSLog("PluginMediaStreamTrack#run()")

		self.rtcMediaStreamTrack.delegate = self
	}


	func getJSON() -> NSDictionary {
		return [
			"id": self.id,
			"kind": self.kind,
			"label": self.rtcMediaStreamTrack.label,
			"enabled": self.rtcMediaStreamTrack.isEnabled() ? true : false,
			"readyState": PluginRTCTypes.mediaStreamTrackStates[self.rtcMediaStreamTrack.state().value] as String!
		]
	}


	func setListener(
		eventListener: (data: NSDictionary) -> Void,
		eventListenerForEnded: () -> Void
	) {
		NSLog("PluginMediaStreamTrack#setListener()")

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
		NSLog("PluginMediaStreamTrack#setEnabled() [value:\(value)]")

		self.rtcMediaStreamTrack.setEnabled(value)
	}


	func stop() {
		NSLog("PluginMediaStreamTrack#stop()")

		self.rtcMediaStreamTrack.setState(RTCTrackStateEnded)
	}


	/**
	 * Methods inherited from RTCMediaStreamTrackDelegate.
	 */


	func mediaStreamTrackDidChange(rtcMediaStreamTrack: RTCMediaStreamTrack!) {
		let state_str = PluginRTCTypes.mediaStreamTrackStates[self.rtcMediaStreamTrack.state().value] as String!

		NSLog("PluginMediaStreamTrack | state changed [state:\(state_str), enabled:\(self.rtcMediaStreamTrack.isEnabled() ? true : false)]")

		if self.eventListener != nil {
			self.eventListener!(data: [
				"type": "statechange",
				"readyState": state_str,
				"enabled": self.rtcMediaStreamTrack.isEnabled() ? true : false
			])

			if self.rtcMediaStreamTrack.state().value == RTCTrackStateEnded.value {
				self.eventListenerForEnded!()
			}
		} else {
			// It may happen that the eventListener is not yet set, so store the lost states.
			self.lostStates.append(state_str)
		}
	}
}
