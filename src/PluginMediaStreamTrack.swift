import Foundation


class PluginMediaStreamTrack : NSObject {
	var rtcMediaStreamTrack: RTCMediaStreamTrack
	var streamId: String
	var id: String
	var kind: String
	var eventListener: ((_ data: NSDictionary) -> Void)?
	var eventListenerForEnded: (() -> Void)?
	var lostStates = Array<String>()
	var renders: [String : PluginMediaStreamRenderer]

	init(rtcMediaStreamTrack: RTCMediaStreamTrack, streamId: String) {
		NSLog("PluginMediaStreamTrack#init()")

		self.rtcMediaStreamTrack = rtcMediaStreamTrack
		self.id = UUID().uuidString;
		self.kind = rtcMediaStreamTrack.kind
		self.renders = [:]
		self.streamId = streamId;
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

		if (self.rtcMediaStreamTrack.isEnabled != value) {
			self.rtcMediaStreamTrack.isEnabled = value
			if (value) {
				self.rtcMediaStreamTrack.videoCaptureController?.startCapture()
			}else {
				self.rtcMediaStreamTrack.videoCaptureController?.stopCapture()
			}
		}
	}
	
	func switchCamera() {
		self.rtcMediaStreamTrack.videoCaptureController?.switchCamera()
	}

	func registerRender(render: PluginMediaStreamRenderer) {
		if let exist = self.renders[render.id] {
			_ = exist
		} else {
			self.renders[render.id] = render
		}
	}
	
	func unregisterRender(render: PluginMediaStreamRenderer) {
		self.renders.removeValue(forKey: render.id);
	}

	func stop() {
		NSLog("PluginMediaStreamTrack#stop() [kind:%@, id:%@]", String(self.kind), String(self.id))

		self.rtcMediaStreamTrack.videoCaptureController?.stopCapture();
		
		// Let's try setEnabled(false), but it also fails.
		self.rtcMediaStreamTrack.isEnabled = false
		
		for (_, render) in self.renders {
			render.stop()
		}
		self.renders.removeAll();
	}
}
