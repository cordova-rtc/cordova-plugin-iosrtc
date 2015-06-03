import Foundation
import AVFoundation


@objc(PluginMediaStreamRenderer)
class PluginMediaStreamRenderer : RTCEAGLVideoViewDelegate {
	var webView: UIWebView
	var eventListener: (data: NSDictionary) -> Void
	var videoTrackView: RTCEAGLVideoView
	var pluginMediaStream: PluginMediaStream?
	var rtcAudioTrack: RTCAudioTrack?
	var rtcVideoTrack: RTCVideoTrack?


	init(
		webView: UIWebView,
		eventListener: (data: NSDictionary) -> Void
	) {
		NSLog("PluginMediaStreamRenderer#init()")

		self.webView = webView
		self.eventListener = eventListener
		self.videoTrackView = RTCEAGLVideoView()

		self.videoTrackView.userInteractionEnabled = false
		self.videoTrackView.hidden = true
		self.videoTrackView.backgroundColor = UIColor.blackColor()

		self.webView.addSubview(self.videoTrackView)
		self.webView.bringSubviewToFront(self.videoTrackView)
	}


	func run() {
		NSLog("PluginMediaStreamRenderer#run()")

		self.videoTrackView.delegate = self
	}


	func render(pluginMediaStream: PluginMediaStream) {
		NSLog("PluginMediaStreamRenderer#render()")

		if self.pluginMediaStream != nil {
			self.reset()
		}

		self.pluginMediaStream = pluginMediaStream

		// Take the first audio track.
		for (id, track) in pluginMediaStream.audioTracks {
			self.rtcAudioTrack = track.rtcMediaStreamTrack as? RTCAudioTrack
			break
		}

		// Take the first video track.
		for (id, track) in pluginMediaStream.videoTracks {
			self.rtcVideoTrack = track.rtcMediaStreamTrack as? RTCVideoTrack
			break
		}

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.addRenderer(self.videoTrackView)
		}
	}


	func mediaStreamChanged() {
		NSLog("PluginMediaStreamRenderer#mediaStreamChanged()")

		if self.pluginMediaStream == nil {
			return
		}

		var oldRtcVideoTrack: RTCVideoTrack? = self.rtcVideoTrack

		self.rtcAudioTrack = nil
		self.rtcVideoTrack = nil

		// Take the first audio track.
		for (id, track) in self.pluginMediaStream!.audioTracks {
			self.rtcAudioTrack = track.rtcMediaStreamTrack as? RTCAudioTrack
			break
		}

		// Take the first video track.
		for (id, track) in pluginMediaStream!.videoTracks {
			self.rtcVideoTrack = track.rtcMediaStreamTrack as? RTCVideoTrack
			break
		}

		// If same video track as before do nothing.
		if oldRtcVideoTrack != nil && self.rtcVideoTrack != nil &&
			oldRtcVideoTrack!.label == self.rtcVideoTrack!.label {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | same video track as before")
		}

		// Different video track.
		else if oldRtcVideoTrack != nil && self.rtcVideoTrack != nil &&
			oldRtcVideoTrack!.label != self.rtcVideoTrack!.label {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | has a new video track")

			oldRtcVideoTrack!.removeRenderer(self.videoTrackView)
			self.rtcVideoTrack!.addRenderer(self.videoTrackView)
		}

		// Did not have video but now it has.
		else if oldRtcVideoTrack == nil && self.rtcVideoTrack != nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track added")

			self.rtcVideoTrack!.addRenderer(self.videoTrackView)
		}

		// Had video but now it has not.
		else if oldRtcVideoTrack != nil && self.rtcVideoTrack == nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track removed")

			oldRtcVideoTrack!.removeRenderer(self.videoTrackView)
		}
	}


	func refresh(
		left: Float,
		top: Float,
		width: Float,
		height: Float,
		visible: Bool,
		opacity: Float,
		zIndex: Float,
		mirrored: Bool
	) {
		NSLog("PluginMediaStreamRenderer#refresh() [left:\(left), top:\(top), width:\(width), height:\(height), visible:\(visible), opacity:\(opacity), zIndex:\(zIndex), mirrored:\(mirrored)]")

		if width == 0 || height == 0 {
			return
		}

		self.videoTrackView.frame = CGRectMake(
			CGFloat(left),
			CGFloat(top),
			CGFloat(width),
			CGFloat(height)
		)

		if visible {
			self.videoTrackView.hidden = false
		} else {
			self.videoTrackView.hidden = true
		}

		if !mirrored {
			// self.videoTrackView.transform = CGAffineTransformMakeScale(1.0, 1.0);
			self.videoTrackView.transform = CGAffineTransformIdentity;
		} else {
			self.videoTrackView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
		}

		self.videoTrackView.alpha = CGFloat(opacity)
		self.videoTrackView.layer.zPosition = CGFloat(zIndex)
	}


	func close() {
		NSLog("PluginMediaStreamRenderer#close()")

		self.reset()

		self.videoTrackView.removeFromSuperview()
	}


	/**
	 * Private API.
	 */


	private func reset() {
		NSLog("PluginMediaStreamRenderer#reset()")

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.removeRenderer(self.videoTrackView)
		}

		self.pluginMediaStream = nil
		self.rtcAudioTrack = nil
		self.rtcVideoTrack = nil
	}


	/**
	 * Methods inherited from RTCEAGLVideoViewDelegate.
	 */


	func videoView(videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
		NSLog("PluginMediaStreamRenderer | video size changed [width:\(size.width), height:\(size.height)]")

		self.eventListener(data: [
			"type": "videoresize",
			"size": [
				"width": Int(size.width),
				"height": Int(size.height)
			]
		])
	}

}
