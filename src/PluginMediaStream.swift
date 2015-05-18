import Foundation


class PluginMediaStream {
	var rtcMediaStream: RTCMediaStream
	var id: String
	var audioTracks: [String : PluginMediaStreamTrack] = [:]
	var videoTracks: [String : PluginMediaStreamTrack] = [:]


	/**
	 * Constructor for pc.onaddstream event and getUserMedia().
	 */
	init(rtcMediaStream: RTCMediaStream) {
		NSLog("PluginMediaStream#init()")

		self.rtcMediaStream = rtcMediaStream
		self.id = rtcMediaStream.label  // Old API uses "label" instead of "id".

		for track: RTCMediaStreamTrack in (self.rtcMediaStream.audioTracks as! Array<RTCMediaStreamTrack>) {
			var pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

			pluginMediaStreamTrack.run()
			self.audioTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}

		for track: RTCMediaStreamTrack in (self.rtcMediaStream.videoTracks as! Array<RTCMediaStreamTrack>) {
			var pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

			pluginMediaStreamTrack.run()
			self.videoTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}
	}


	func getJSON() -> NSDictionary {
		var json: NSMutableDictionary = [
			"id": self.id,
			"audioTracks": NSMutableDictionary(),
			"videoTracks": NSMutableDictionary()
		]

		for (id, pluginMediaStreamTrack) in self.audioTracks {
			(json["audioTracks"] as! NSMutableDictionary)[id] = pluginMediaStreamTrack.getJSON()
		}

		for (id, pluginMediaStreamTrack) in self.videoTracks {
			(json["videoTracks"] as! NSMutableDictionary)[id] = pluginMediaStreamTrack.getJSON()
		}

		return json as NSDictionary
	}


	func addTrack(pluginMediaStreamTrack: PluginMediaStreamTrack) -> Bool {
		NSLog("PluginMediaStream#addTrack()")

		if pluginMediaStreamTrack.kind == "audio" {
			if self.rtcMediaStream.addAudioTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCAudioTrack) {
				NSLog("PluginMediaStream#addTrack() | audio track added")
				self.audioTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
				return true
			} else {
				NSLog("PluginMediaStream#addTrack() | ERROR: audio track not added")
				return false
			}
		} else if pluginMediaStreamTrack.kind == "video" {
			if self.rtcMediaStream.addVideoTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCVideoTrack) {
				NSLog("PluginMediaStream#addTrack() | video track added")
				self.videoTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
				return true
			} else {
				NSLog("PluginMediaStream#addTrack() | ERROR: video track not added")
				return false
			}
		}

		return false
	}


	func removeTrack(pluginMediaStreamTrack: PluginMediaStreamTrack) -> Bool {
		NSLog("PluginMediaStream#removeTrack()")

		if pluginMediaStreamTrack.kind == "audio" {
			if self.rtcMediaStream.removeAudioTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCAudioTrack) {
				NSLog("PluginMediaStream#removeTrack() | audio track removed")
				self.audioTracks[pluginMediaStreamTrack.id] = nil
				return true
			} else {
				NSLog("PluginMediaStream#removeTrack() | ERROR: audio track not removed")
				return false
			}
		} else if pluginMediaStreamTrack.kind == "video" {
			if self.rtcMediaStream.removeVideoTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCVideoTrack) {
				NSLog("PluginMediaStream#removeTrack() | video track removed")
				self.videoTracks[pluginMediaStreamTrack.id] = nil
				return true
			} else {
				NSLog("PluginMediaStream#removeTrack() | ERROR: video track not removed")
				return false
			}
		}

		return false
	}


	// TODO: API methods
}
