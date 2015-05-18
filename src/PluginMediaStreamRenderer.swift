import Foundation
import AVFoundation


@objc(PluginMediaStreamRenderer)
class PluginMediaStreamRenderer : RTCEAGLVideoViewDelegate {
	var webView: UIWebView
	var eventListener: (data: NSDictionary) -> Void
	var videoTrackView: RTCEAGLVideoView
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

		if self.rtcAudioTrack != nil || self.rtcVideoTrack != nil {
			self.reset()
		}

		for (id, track) in pluginMediaStream.audioTracks {
			self.rtcAudioTrack = track.rtcMediaStreamTrack as? RTCAudioTrack
			break
		}

		for (id, track) in pluginMediaStream.videoTracks {
			self.rtcVideoTrack = track.rtcMediaStreamTrack as? RTCVideoTrack
			break
		}

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.addRenderer(self.videoTrackView)
		}
	}


	func refresh(
		left: Float,
		top: Float,
		width: Float,
		height: Float,
		visible: Bool,
		opacity: Float,
		zIndex: Float
	) {
		NSLog("PluginMediaStreamRenderer#refresh() [left:\(left), top:\(top), width:\(width), height:\(height), visible:\(visible), opacity:\(opacity), zIndex:\(zIndex)]")

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
