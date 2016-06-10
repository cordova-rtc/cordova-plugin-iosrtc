import Foundation
import AVFoundation


class PluginMediaStreamRenderer : NSObject, RTCEAGLVideoViewDelegate {
	var webView: UIView
	var eventListener: (data: NSDictionary) -> Void
	var elementView: UIView
	var videoView: RTCEAGLVideoView
	var pluginMediaStream: PluginMediaStream?
	var rtcAudioTrack: RTCAudioTrack?
	var rtcVideoTrack: RTCVideoTrack?


	init(
		webView: UIView,
		eventListener: (data: NSDictionary) -> Void
	) {
		NSLog("PluginMediaStreamRenderer#init()")

		// The browser HTML view.
		self.webView = webView
		self.eventListener = eventListener
		// The video element view.
		self.elementView = UIView()
		// The effective video view in which the the video stream is shown.
		// It's placed over the elementView.
		self.videoView = RTCEAGLVideoView()

		self.elementView.userInteractionEnabled = false
		self.elementView.hidden = true
		self.elementView.backgroundColor = UIColor.blackColor()
		self.elementView.addSubview(self.videoView)
		self.elementView.layer.masksToBounds = true

		self.videoView.userInteractionEnabled = false

		// Place the video element view inside the WebView's superview
		self.webView.superview?.addSubview(self.elementView)
	}


	deinit {
		NSLog("PluginMediaStreamRenderer#deinit()")
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
		for (_, track) in pluginMediaStream.audioTracks {
			self.rtcAudioTrack = track.rtcMediaStreamTrack as? RTCAudioTrack
			break
		}

		// Take the first video track.
		for (_, track) in pluginMediaStream.videoTracks {
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

		let oldRtcVideoTrack: RTCVideoTrack? = self.rtcVideoTrack

		self.rtcAudioTrack = nil
		self.rtcVideoTrack = nil

		// Take the first audio track.
		for (_, track) in self.pluginMediaStream!.audioTracks {
			self.rtcAudioTrack = track.rtcMediaStreamTrack as? RTCAudioTrack
			break
		}

		// Take the first video track.
		for (_, track) in pluginMediaStream!.videoTracks {
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


	func refresh(data: NSDictionary) {
		let elementLeft = data.objectForKey("elementLeft") as? Float ?? 0
		let elementTop = data.objectForKey("elementTop") as? Float ?? 0
		let elementWidth = data.objectForKey("elementWidth") as? Float ?? 0
		let elementHeight = data.objectForKey("elementHeight") as? Float ?? 0
		var videoViewWidth = data.objectForKey("videoViewWidth") as? Float ?? 0
		var videoViewHeight = data.objectForKey("videoViewHeight") as? Float ?? 0
		let visible = data.objectForKey("visible") as? Bool ?? true
		let opacity = data.objectForKey("opacity") as? Float ?? 1
		let zIndex = data.objectForKey("zIndex") as? Float ?? 0
		let mirrored = data.objectForKey("mirrored") as? Bool ?? false
		let clip = data.objectForKey("clip") as? Bool ?? true
		let borderRadius = data.objectForKey("borderRadius") as? Float ?? 0

		NSLog("PluginMediaStreamRenderer#refresh() [elementLeft:%@, elementTop:%@, elementWidth:%@, elementHeight:%@, videoViewWidth:%@, videoViewHeight:%@, visible:%@, opacity:%@, zIndex:%@, mirrored:%@, clip:%@, borderRadius:%@]",
			String(elementLeft), String(elementTop), String(elementWidth), String(elementHeight),
			String(videoViewWidth), String(videoViewHeight), String(visible), String(opacity), String(zIndex),
			String(mirrored), String(clip), String(borderRadius))

		let videoViewLeft: Float = (elementWidth - videoViewWidth) / 2
		let videoViewTop: Float = (elementHeight - videoViewHeight) / 2

		self.elementView.frame = CGRectMake(
			CGFloat(elementLeft),
			CGFloat(elementTop),
			CGFloat(elementWidth),
			CGFloat(elementHeight)
		)

		// NOTE: Avoid a zero-size UIView for the video (the library complains).
		if videoViewWidth == 0 || videoViewHeight == 0 {
			videoViewWidth = 1
			videoViewHeight = 1
			self.videoView.hidden = true
		} else {
			self.videoView.hidden = false
		}

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

                // if the zIndex is 0 (the default) bring the view to the top, last one wins
                if zIndex == 0 {
			self.webView.superview?.bringSubviewToFront(self.elementView)
                }

		if !mirrored {
			self.elementView.transform = CGAffineTransformIdentity
		} else {
			self.elementView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
		}

		if clip {
			self.elementView.clipsToBounds = true
		} else {
			self.elementView.clipsToBounds = false
		}

		self.elementView.layer.cornerRadius = CGFloat(borderRadius)
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
		NSLog("PluginMediaStreamRenderer | video size changed [width:%@, height:%@]",
			String(size.width), String(size.height))

		self.eventListener(data: [
			"type": "videoresize",
			"size": [
				"width": Int(size.width),
				"height": Int(size.height)
			]
		])
	}

}
