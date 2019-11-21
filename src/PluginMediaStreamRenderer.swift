import Foundation
import AVFoundation

class PluginRTCVideoView : UIView {
	
	var mirror: Bool = false

#if RTC_SUPPORTS_METAL
	var rtcVideoView: RTCMTLVideoView?
#else
	var rtcVideoView: RTCEAGLVideoView?
#endif
	
	/**
	 * The width and height of the video (frames) rendered by {@link #subview}.
	 */
	var _videoSize : CGSize = CGSize(width: 0, height: 0);
	
	public convenience init(){
		self.init(frame: .zero)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)

#if RTC_SUPPORTS_METAL
		self.rtcVideoView = RTCMTLVideoView.init(frame: frame)
#else
		self.rtcVideoView = RTCEAGLVideoView.init(frame: frame)
#endif
		
		self.rtcVideoView!.isUserInteractionEnabled = false
		self.rtcVideoView!.frame = self.bounds
		self.addSubview(self.rtcVideoView!)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
#if RTC_SUPPORTS_METAL
		self.rtcVideoView = RTCMTLVideoView.init(coder: aDecoder)
#else
		self.rtcVideoView = RTCEAGLVideoView.init(coder: aDecoder)
#endif
		
		self.rtcVideoView!.isUserInteractionEnabled = false
		self.rtcVideoView!.frame = self.bounds
		self.addSubview(self.rtcVideoView!)
	}
	
	// TODO
	public func setSize(size: CGSize) {
		//self._videoSize = size;
		//self.rtcVideoView?.setSize(size)
	}
	
	// TODO
	public override func layoutSubviews() {
	   //if(self.rtcVideoView != nil){
		   //self.rtcVideoView!.frame = self.bounds
	   //}
	}
	
	public func setMirror(mirror: Bool){
		if (self.mirror) {
			self.mirror = true
			self.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
		} else {
			self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0);
			self.mirror = false;
		}
	}
}

class PluginMediaStreamRenderer : NSObject, RTCEAGLVideoViewDelegate {
	
	var id: String
	var eventListener: (_ data: NSDictionary) -> Void
	var closed: Bool
	
	var webView: UIView
	var videoView: PluginRTCVideoView
	var pluginMediaStream: PluginMediaStream?
	var rtcAudioTrack: RTCAudioTrack?
	var rtcVideoTrack: RTCVideoTrack?

	init(
		webView: UIView,
		eventListener: @escaping (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginMediaStreamRenderer#init()")
		
		// Open Renderer
		self.id = UUID().uuidString;
		self.closed = false
		
		// The browser HTML view.
		self.webView = webView
		self.eventListener = eventListener
		
		// The video element view.
		self.videoView = PluginRTCVideoView()
		
		
		self.videoView.isUserInteractionEnabled = false
		self.videoView.isHidden = true
		self.videoView.backgroundColor = UIColor.black
		self.videoView.layer.masksToBounds = true
		
		// Place the video element view inside the WebView's superview
		self.webView.addSubview(self.videoView)
		self.webView.isOpaque = false
		self.webView.backgroundColor = UIColor.clear

		/*
		// The effective video view in which the the video stream is shown.
		// It's placed over the elementView.
		self.videoView = RTCEAGLVideoView(frame: CGRect.zero)
		self.videoView.isUserInteractionEnabled = false

		self.elementView.isUserInteractionEnabled = false
		self.elementView.isHidden = true
		self.elementView.backgroundColor = UIColor.black
		self.elementView.addSubview(self.videoView)
		self.elementView.layer.masksToBounds = true

		// Place the video element view inside the WebView's superview
		self.webView.addSubview(self.elementView)
		self.webView.isOpaque = false
		self.webView.backgroundColor = UIColor.clear
		 */
		
		/*
		// https://stackoverflow.com/questions/46317061/use-safe-area-layout-programmatically
		// https://developer.apple.com/documentation/uikit/uiview/2891102-safearealayoutguide
		// https://developer.apple.com/documentation/uikit/
		let view = self.elementView;
		if #available(iOS 11.0, *) {
			let guide = webView.safeAreaLayoutGuide;
			view.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
			view.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
			view.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
			view.rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
		} else {
			NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: webView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
			NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: webView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
			NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: webView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
			NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: webView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
		}
		*/
	}

	deinit {
		NSLog("PluginMediaStreamRenderer#deinit()")
	}

	func run() {
		NSLog("PluginMediaStreamRenderer#run()")
		
		self.videoView.rtcVideoView!.delegate = self
	}

	func render(_ pluginMediaStream: PluginMediaStream) {
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
		var pluginVideoTrack: PluginMediaStreamTrack?
		for (_, track) in pluginMediaStream.videoTracks {
			pluginVideoTrack = track
			
			if (self.rtcVideoTrack == track.rtcMediaStreamTrack) {
				return;
			}
			self.rtcVideoTrack = track.rtcMediaStreamTrack as? RTCVideoTrack
			break
		}

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.add(self.videoView.rtcVideoView!)
			pluginVideoTrack?.registerRender(render: self)
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
			oldRtcVideoTrack!.trackId == self.rtcVideoTrack!.trackId {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | same video track as before")
		}

		// Different video track.
		else if oldRtcVideoTrack != nil && self.rtcVideoTrack != nil &&
			oldRtcVideoTrack!.trackId != self.rtcVideoTrack!.trackId {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | has a new video track")

			oldRtcVideoTrack!.remove(self.videoView.rtcVideoView!)
			self.rtcVideoTrack!.add(self.videoView.rtcVideoView!)
		}

		// Did not have video but now it has.
		else if oldRtcVideoTrack == nil && self.rtcVideoTrack != nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track added")

			self.rtcVideoTrack!.add(self.videoView.rtcVideoView!)
		}

		// Had video but now it has not.
		else if oldRtcVideoTrack != nil && self.rtcVideoTrack == nil {
			NSLog("PluginMediaStreamRenderer#mediaStreamChanged() | video track removed")
			oldRtcVideoTrack!.remove(self.videoView.rtcVideoView!)
		}
	}

	func refresh(_ data: NSDictionary) {
		
		let elementLeft = data.object(forKey: "elementLeft") as? Double ?? 0
		let elementTop = data.object(forKey: "elementTop") as? Double ?? 0
		let elementWidth = data.object(forKey: "elementWidth") as? Double ?? 0
		let elementHeight = data.object(forKey: "elementHeight") as? Double ?? 0
		let videoViewWidth = data.object(forKey: "videoViewWidth") as? Double ?? 0
		let videoViewHeight = data.object(forKey: "videoViewHeight") as? Double ?? 0
		let visible = data.object(forKey: "visible") as? Bool ?? true
		let opacity = data.object(forKey: "opacity") as? Double ?? 1
		let zIndex = data.object(forKey: "zIndex") as? Double ?? 0
		let mirrored = data.object(forKey: "mirrored") as? Bool ?? false
		let clip = data.object(forKey: "clip") as? Bool ?? true
		let borderRadius = data.object(forKey: "borderRadius") as? Double ?? 0

		NSLog("PluginMediaStreamRenderer#refresh() [elementLeft:%@, elementTop:%@, elementWidth:%@, elementHeight:%@, videoViewWidth:%@, videoViewHeight:%@, visible:%@, opacity:%@, zIndex:%@, mirrored:%@, clip:%@, borderRadius:%@]",
			String(elementLeft), String(elementTop), String(elementWidth), String(elementHeight),
			String(videoViewWidth), String(videoViewHeight), String(visible), String(opacity), String(zIndex),
			String(mirrored), String(clip), String(borderRadius))

		let videoViewLeft: Double = (elementWidth - videoViewWidth) / 2
		let videoViewTop: Double = (elementHeight - videoViewHeight) / 2
		
		var oldValue : CGRect,
			newValue : CGRect;
		
		// Resize videoView only if needed
		if (elementWidth <= 0 || elementHeight <= 0) {
			newValue = videoView.bounds;
		}  else {
			newValue = CGRect(
				x: CGFloat(elementLeft),
				y: CGFloat(elementTop),
				width: CGFloat(elementWidth),
				height: CGFloat(elementHeight)
			)
	   }
		
		oldValue = videoView.frame;
		if (
			newValue.origin.x != oldValue.origin.x
				|| newValue.origin.y != oldValue.origin.y
					|| newValue.size.width != oldValue.size.width
					|| newValue.size.height != oldValue.size.height
		) {
		
			NSLog("PluginMediaStreamRenderer#refresh() videoView frame changed")
			videoView.frame = newValue;
		}
		
		// Resize rtcVideoView only if needed to apply aspect ratio
		newValue = CGRect(
			x: CGFloat(videoViewLeft),
			y: CGFloat(videoViewTop),
			width: CGFloat(videoViewWidth),
			height: CGFloat(videoViewHeight)
		)
		oldValue = videoView.rtcVideoView!.frame;
		if (
			newValue.origin.x != oldValue.origin.x
				|| newValue.origin.y != oldValue.origin.y
					|| newValue.size.width != oldValue.size.width
					|| newValue.size.height != oldValue.size.height
		) {
			
			NSLog("PluginMediaStreamRenderer#refresh() rtcVideoView frame changed")
			videoView.rtcVideoView!.frame = newValue;
		}

		if (visible && (videoViewWidth != 0 && videoViewHeight != 0)) {
			videoView.isHidden = false
		} else {
			videoView.isHidden = true
		}

		videoView.alpha = CGFloat(opacity)
		videoView.layer.zPosition = CGFloat(zIndex)

		// if the zIndex is 0 (the default) bring the view to the top, last one wins
		if zIndex == 0 {
			webView.bringSubviewToFront(videoView)
			//self.webView?.bringSubview(toFront: self.videoView)
		}

		videoView.setMirror(mirror: mirrored)

		if clip {
			videoView.clipsToBounds = true
		} else {
			videoView.clipsToBounds = false
		}

		videoView.layer.cornerRadius = CGFloat(borderRadius)
	}
	
	func save() -> String {
		NSLog("PluginMediaStreamRenderer#save()")
		UIGraphicsBeginImageContextWithOptions(videoView.bounds.size, videoView.isOpaque, 0.0)
		videoView.drawHierarchy(in: videoView.bounds, afterScreenUpdates: false)
		let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		let imageData = snapshotImageFromMyView?.jpegData(compressionQuality: 1.0)
		let strBase64 = imageData?.base64EncodedString(options: .lineLength64Characters)
		return strBase64!;
	}
	
	func stop() {
		NSLog("PluginMediaStreamRenderer | video stop")
		
		self.eventListener([
			"type": "videostop"
		])
	}

	func close() {
		NSLog("PluginMediaStreamRenderer#close()")
		self.closed = true
		self.reset()
		self.videoView.removeFromSuperview()
	}

	/**
	 * Private API.
	 */
	
	fileprivate func reset() {
		NSLog("PluginMediaStreamRenderer#reset()")

		if self.rtcVideoTrack != nil {
			self.rtcVideoTrack!.remove(self.videoView.rtcVideoView!)
		}

		self.pluginMediaStream = nil
		self.rtcAudioTrack = nil
		self.rtcVideoTrack = nil
	}

	/**
	 * Methods inherited from RTCEAGLVideoViewDelegate.
	 */
	
	func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
	
		NSLog("PluginMediaStreamRenderer | video size changed [width:%@, height:%@]",
			String(describing: size.width), String(describing: size.height))

		self.eventListener([
			"type": "videoresize",
			"size": [
				"width": Int(size.width),
				"height": Int(size.height)
			]
		])
	}
	
	func videoView(_ videoView: RTCVideoRenderer, didChange frame: RTCVideoFrame?) {
		
		// TODO save from frame buffer instead of renderer
		/*
		let i420: RTCI420BufferProtocol = frame!.buffer.toI420()
		let YPtr: UnsafePointer<UInt8> = i420.dataY
		let UPtr: UnsafePointer<UInt8> = i420.dataU
		let VPtr: UnsafePointer<UInt8> = i420.dataV
		let YSize: Int = Int(frame!.width * frame!.height)
		let USize: Int = Int(YSize / 4)
		let VSize: Int = Int(YSize / 4)
		var frameSize:Int32 = Int32(YSize + USize + VSize)
		var width: Int16 = Int16(frame!.width)
		var height: Int16 = Int16(frame!.height)
		var rotation: Int16 = Int16(frame!.rotation.rawValue)
		var timestamp: Int32 = Int32(frame!.timeStamp)
		
		// head + body
		// head: type(2B)+len(4B)+width(2B)+height(2B)+rotation(2B)+timestamp(4B)
		// body: data(len)
		let headSize:Int32 = 16
		let dataSize:Int32 = headSize + frameSize
		let pduData: NSMutableData? = NSMutableData(length: Int(dataSize))
		
		let headPtr = pduData!.mutableBytes
		var pduType:UInt16 = 0x2401
		memcpy(headPtr, &pduType, 2)
		memcpy(headPtr+2, &frameSize, 4)
		memcpy(headPtr+2+4, &width, 2)
		memcpy(headPtr+2+4+2, &height, 2)
		memcpy(headPtr+2+4+2+2, &rotation, 2)
		//memcpy(headPtr+2+4+2+2+2, &timestamp, 4)
		
		let bodyPtr = pduData!.mutableBytes + Int(headSize)
		memcpy(bodyPtr, YPtr, YSize)
		memcpy(bodyPtr + YSize, UPtr, USize);
		memcpy(bodyPtr + YSize + USize, VPtr, VSize);
		*/
	}
}
