import Foundation
import AVFoundation


@objc(PluginMediaStreamRenderer)
class PluginMediaStreamRenderer : RTCEAGLVideoViewDelegate {
	var webView: UIWebView
	var eventListener: (data: NSDictionary) -> Void
	var elementView: UIView
	var videoView: RTCEAGLVideoView
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
		self.elementView = RTCEAGLVideoView()
		self.videoView = RTCEAGLVideoView()

		self.webView.addSubview(self.elementView)
		self.webView.bringSubviewToFront(self.elementView)

		self.elementView.userInteractionEnabled = false
		self.elementView.hidden = true
		self.elementView.backgroundColor = UIColor.blackColor()
		self.elementView.addSubview(self.videoView)
		self.elementView.bringSubviewToFront(self.videoView)

		self.videoView.userInteractionEnabled = false
	}


	func run() {
		NSLog("PluginMediaStreamRenderer#run()")

		self.videoView.delegate = self
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
			self.rtcVideoTrack!.addRenderer(self.videoView)
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

			oldRtcVideoTrack!.removeRenderer(self.videoView)
			self.rtcVideoTrack!.addRenderer(self.videoView)
		}

		// Did not have video but now it has.
		else if oldRtcVideoTrack == nil && self.rtcVideoTrack != nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track added")

			self.rtcVideoTrack!.addRenderer(self.videoView)
		}

		// Had video but now it has not.
		else if oldRtcVideoTrack != nil && self.rtcVideoTrack == nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track removed")

			oldRtcVideoTrack!.removeRenderer(self.videoView)
		}
	}


	func refresh(
		elementLeft: Float,
		elementTop: Float,
		elementWidth: Float,
		elementHeight: Float,
		videoViewWidth: Float,
		videoViewHeight: Float,
		visible: Bool,
		opacity: Float,
		zIndex: Float,
		mirrored: Bool,
		clip: Bool
	) {

		NSLog("PluginMediaStreamRenderer#refresh() [elementLeft:\(elementLeft), elementTop:\(elementTop), elementWidth:\(elementWidth), elementHeight:\(elementHeight), videoViewWidth:\(videoViewWidth), videoViewHeight:\(videoViewHeight), visible:\(visible), opacity:\(opacity), zIndex:\(zIndex), mirrored:\(mirrored), clip:\(clip)]")

		var videoViewLeft: Float
		var videoViewTop: Float

		if elementWidth == 0 || elementHeight == 0 {
			return
		}

		self.elementView.frame = CGRectMake(
			CGFloat(elementLeft),
			CGFloat(elementTop),
			CGFloat(elementWidth),
			CGFloat(elementHeight)
		)

		videoViewLeft = (elementWidth - videoViewWidth) / 2
		videoViewTop = (elementHeight - videoViewHeight) / 2

		self.videoView.frame = CGRectMake(
			CGFloat(videoViewLeft),
			CGFloat(videoViewTop),
			CGFloat(videoViewWidth),
			CGFloat(videoViewHeight)
		)

		if visible {
			self.elementView.hidden = false
		} else {
			self.elementView.hidden = true
		}

		self.elementView.alpha = CGFloat(opacity)
		self.elementView.layer.zPosition = CGFloat(zIndex)

		if !mirrored {
			self.elementView.transform = CGAffineTransformIdentity
		} else {
			self.elementView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
		}

		if (clip) {
			self.elementView.clipsToBounds = true
		} else {
			self.elementView.clipsToBounds = false
		}
	}


	func close() {
		NSLog("PluginMediaStreamRenderer#close()")

		self.reset()
		self.elementView.removeFromSuperview()
	}


	/**
	 * Private API.
	 */


	private func reset() {
		NSLog("PluginMediaStreamRenderer#reset()")

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.removeRenderer(self.videoView)
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
