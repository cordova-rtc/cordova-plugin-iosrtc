import Foundation

class PluginRTCRtpReceiver : NSObject {
	var rtpReceiver: RTCRtpReceiver
	var id: Int
	
	init(_ rtpReceiver: RTCRtpReceiver, _ id: Int) {
		self.rtpReceiver = rtpReceiver
		self.id = id != 0 ? id : Int.random(in: 0...10000)
    }
	
	func getJSON() -> NSDictionary {
		let track = self.rtpReceiver.track != nil ? [
			"id": self.rtpReceiver.track!.trackId,
			   "kind": self.rtpReceiver.track!.kind,
			   "readyState": self.rtpReceiver.track!.readyState == RTCMediaStreamTrackState.live ? "live" : "ended",
			   "enabled": self.rtpReceiver.track!.isEnabled,
			   "label": self.rtpReceiver.track!.trackId
		] : nil
		return [
			"id": self.id,
			"receiverId": self.rtpReceiver.receiverId,
			"params": PluginRTCRtpParameters(self.rtpReceiver.parameters).getJSON(),
			"track": track
		]
	}

}
