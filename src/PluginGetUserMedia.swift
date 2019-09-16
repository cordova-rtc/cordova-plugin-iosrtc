import Foundation
import AVFoundation


class PluginGetUserMedia {
	static var rtcVideoSource: RTCAVFoundationVideoSource?
	let kARDMediaStreamId = "ARDAMS";
	let kARDAudioTrackId = "ARDAMSa0";
	let kARDVideoTrackId = "ARDAMSv0";
	let kARDVideoTrackKind = "video";

	var rtcPeerConnectionFactory: RTCPeerConnectionFactory


	init(rtcPeerConnectionFactory: RTCPeerConnectionFactory) {
		NSLog("PluginGetUserMedia#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
	}


	deinit {
		NSLog("PluginGetUserMedia#deinit()")
	}


	func call(
		_ constraints: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: (_ error: String) -> Void,
		eventListenerForNewStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	) {
		NSLog("PluginGetUserMedia#call()")

		let	audioRequested = constraints.object(forKey: "audio") as? Bool ?? false
		let	videoRequested = constraints.object(forKey: "video") as? Bool ?? false
		let	videoDeviceId = constraints.object(forKey: "videoDeviceId") as? String
		let	videoMinWidth = constraints.object(forKey: "videoMinWidth") as? Int ?? 0
		let	videoMaxWidth = constraints.object(forKey: "videoMaxWidth") as? Int ?? 640
		let	videoMinHeight = constraints.object(forKey: "videoMinHeight") as? Int ?? 0
		let	videoMaxHeight = constraints.object(forKey: "videoMaxHeight") as? Int ?? 640
		let	videoMinFrameRate = constraints.object(forKey: "videoMinFrameRate") as? Float ?? 0.0
		let	videoMaxFrameRate = constraints.object(forKey: "videoMaxFrameRate") as? Float ?? 25.0

		var rtcMediaStream: RTCMediaStream
		var pluginMediaStream: PluginMediaStream?
		var rtcAudioTrack: RTCAudioTrack?
		var rtcVideoTrack: RTCVideoTrack?
		var usingFront: Bool = true
		var mandatoryConstraints: [String: String] = [:]
		var constraints: RTCMediaConstraints

		if videoRequested == true {
			switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
			case AVAuthorizationStatus.notDetermined:
				NSLog("PluginGetUserMedia#call() | video authorization: not determined")
			case AVAuthorizationStatus.authorized:
				NSLog("PluginGetUserMedia#call() | video authorization: authorized")
			case AVAuthorizationStatus.denied:
				NSLog("PluginGetUserMedia#call() | video authorization: denied")
				errback("video denied")
				return
			case AVAuthorizationStatus.restricted:
				NSLog("PluginGetUserMedia#call() | video authorization: restricted")
				errback("video restricted")
				return
			}
		}

		if audioRequested == true {
			switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) {
			case AVAuthorizationStatus.notDetermined:
				NSLog("PluginGetUserMedia#call() | audio authorization: not determined")
			case AVAuthorizationStatus.authorized:
				NSLog("PluginGetUserMedia#call() | audio authorization: authorized")
			case AVAuthorizationStatus.denied:
				NSLog("PluginGetUserMedia#call() | audio authorization: denied")
				errback("audio denied")
				return
			case AVAuthorizationStatus.restricted:
				NSLog("PluginGetUserMedia#call() | audio authorization: restricted")
				errback("audio restricted")
				return
			}
		}

		rtcMediaStream = self.rtcPeerConnectionFactory.mediaStream(withStreamId: UUID().uuidString)

		if videoRequested == true {
			// Video device specified.
			if videoDeviceId != nil {
				NSLog("PluginGetUserMedia#call() | video requested (specified device id: '%@')", String(videoDeviceId!))

				for device: AVCaptureDevice in (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! Array<AVCaptureDevice>) {
					if device.uniqueID == videoDeviceId {
						if device.position == AVCaptureDevicePosition.back {
							usingFront = false
							break
						}
					}
				}
			}

			NSLog("PluginGetUserMedia#call() | chosen video device usingFront: %@", String(describing: usingFront))

			if videoMinWidth > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [minWidth:%@]", String(videoMinWidth))
				mandatoryConstraints["minWidth"] = String(videoMinWidth)
			}
			if videoMaxWidth > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [maxWidth:%@]", String(videoMaxWidth))
				mandatoryConstraints["maxWidth"] = String(videoMaxWidth)
			}
			if videoMinHeight > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [minHeight:%@]", String(videoMinHeight))
				mandatoryConstraints["minHeight"] = String(videoMinHeight)
			}
			if videoMaxHeight > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [maxHeight:%@]", String(videoMaxHeight))
				mandatoryConstraints["maxHeight"] = String(videoMaxHeight)
			}
			if videoMinFrameRate > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [videoMinFrameRate:%@]", String(videoMinFrameRate))
				mandatoryConstraints["minFrameRate"] = String(videoMinFrameRate)
			}
			if videoMaxFrameRate > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [videoMaxFrameRate:%@]", String(videoMaxFrameRate))
				mandatoryConstraints["maxFrameRate"] = String(videoMaxFrameRate)
			}

			constraints = RTCMediaConstraints(
				mandatoryConstraints: mandatoryConstraints,
				optionalConstraints: [:]
			)

			if(PluginGetUserMedia.rtcVideoSource == nil){
				PluginGetUserMedia.rtcVideoSource = self.rtcPeerConnectionFactory.avFoundationVideoSource(with: constraints);
			}
            PluginGetUserMedia.rtcVideoSource?.useBackCamera = !usingFront
			
			// If videoSource state is "ended" it means that constraints were not satisfied so
			// invoke the given errback.
			if (PluginGetUserMedia.rtcVideoSource!.state == RTCSourceState.ended) {
				NSLog("PluginGetUserMedia() | PluginGetUserMedia.rtcVideoSource.state is 'ended', constraints not satisfied")

				errback("constraints not satisfied")
				return
			}

			rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrack(with: PluginGetUserMedia.rtcVideoSource!, trackId: UUID().uuidString)

			rtcMediaStream.addVideoTrack(rtcVideoTrack!)
		}

		if audioRequested == true {
			NSLog("PluginGetUserMedia#call() | audio requested")

			rtcAudioTrack = self.rtcPeerConnectionFactory.audioTrack(withTrackId: UUID().uuidString)

			rtcMediaStream.addAudioTrack(rtcAudioTrack!)
		}

		pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
		pluginMediaStream!.run()

		// Let the plugin store it in its dictionary.
		eventListenerForNewStream(pluginMediaStream!)

		callback([
			"stream": pluginMediaStream!.getJSON()
		])
	}
}
