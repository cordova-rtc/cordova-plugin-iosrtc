import Foundation
import AVFoundation


class PluginGetUserMedia {
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory


	init(rtcPeerConnectionFactory: RTCPeerConnectionFactory) {
		NSLog("PluginGetUserMedia#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
	}


	deinit {
		NSLog("PluginGetUserMedia#deinit()")
	}


	func call(
		constraints: NSDictionary,
		callback: (data: NSDictionary) -> Void,
		errback: (error: String) -> Void,
		eventListenerForNewStream: (pluginMediaStream: PluginMediaStream) -> Void
	) {
		NSLog("PluginGetUserMedia#call()")

		let	audioRequested = constraints.objectForKey("audio") as? Bool ?? false
		let	videoRequested = constraints.objectForKey("video") as? Bool ?? false
		let	videoDeviceId = constraints.objectForKey("videoDeviceId") as? String
		let	videoMinWidth = constraints.objectForKey("videoMinWidth") as? Int ?? 0
		let	videoMaxWidth = constraints.objectForKey("videoMaxWidth") as? Int ?? 0
		let	videoMinHeight = constraints.objectForKey("videoMinHeight") as? Int ?? 0
		let	videoMaxHeight = constraints.objectForKey("videoMaxHeight") as? Int ?? 0
		let	videoMinFrameRate = constraints.objectForKey("videoMinFrameRate") as? Float ?? 0.0
		let	videoMaxFrameRate = constraints.objectForKey("videoMaxFrameRate") as? Float ?? 0.0

		var rtcMediaStream: RTCMediaStream
		var pluginMediaStream: PluginMediaStream?
		var rtcAudioTrack: RTCAudioTrack?
		var rtcVideoTrack: RTCVideoTrack?
		var rtcVideoCapturer: RTCVideoCapturer?
		var rtcVideoSource: RTCVideoSource?
		var videoDevice: AVCaptureDevice?
		var mandatoryConstraints: [RTCPair] = []
		var constraints: RTCMediaConstraints

		if videoRequested == true {
			switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
			case AVAuthorizationStatus.NotDetermined:
				NSLog("PluginGetUserMedia#call() | video authorization: not determined")
			case AVAuthorizationStatus.Authorized:
				NSLog("PluginGetUserMedia#call() | video authorization: authorized")
			case AVAuthorizationStatus.Denied:
				NSLog("PluginGetUserMedia#call() | video authorization: denied")
				errback(error: "video denied")
				return
			case AVAuthorizationStatus.Restricted:
				NSLog("PluginGetUserMedia#call() | video authorization: restricted")
				errback(error: "video restricted")
				return
			}
		}

		if audioRequested == true {
			switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) {
			case AVAuthorizationStatus.NotDetermined:
				NSLog("PluginGetUserMedia#call() | audio authorization: not determined")
			case AVAuthorizationStatus.Authorized:
				NSLog("PluginGetUserMedia#call() | audio authorization: authorized")
			case AVAuthorizationStatus.Denied:
				NSLog("PluginGetUserMedia#call() | audio authorization: denied")
				errback(error: "audio denied")
				return
			case AVAuthorizationStatus.Restricted:
				NSLog("PluginGetUserMedia#call() | audio authorization: restricted")
				errback(error: "audio restricted")
				return
			}
		}

		rtcMediaStream = self.rtcPeerConnectionFactory.mediaStreamWithLabel(NSUUID().UUIDString)

		if videoRequested == true {
			// No specific video device requested.
			if videoDeviceId == nil {
				NSLog("PluginGetUserMedia#call() | video requested (device not specified)")

				for device: AVCaptureDevice in (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! Array<AVCaptureDevice>) {
					if device.position == AVCaptureDevicePosition.Front {
						videoDevice = device
						break
					}
				}
			}

			// Video device specified.
			else {
				NSLog("PluginGetUserMedia#call() | video requested (specified device id: '%@')", String(videoDeviceId!))

				for device: AVCaptureDevice in (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! Array<AVCaptureDevice>) {
					if device.uniqueID == videoDeviceId {
						videoDevice = device
						break
					}
				}
			}

			if videoDevice == nil {
				NSLog("PluginGetUserMedia#call() | video requested but no suitable device found")

				errback(error: "no suitable camera device found")
				return
			}

			NSLog("PluginGetUserMedia#call() | chosen video device: %@", String(videoDevice!))

			rtcVideoCapturer = RTCVideoCapturer(deviceName: videoDevice!.localizedName)

			if videoMinWidth > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [minWidth:%@]", String(videoMinWidth))
				mandatoryConstraints.append(RTCPair(key: "minWidth", value: String(videoMinWidth)))
			}
			if videoMaxWidth > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [maxWidth:%@]", String(videoMaxWidth))
				mandatoryConstraints.append(RTCPair(key: "maxWidth", value: String(videoMaxWidth)))
			}
			if videoMinHeight > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [minHeight:%@]", String(videoMinHeight))
				mandatoryConstraints.append(RTCPair(key: "minHeight", value: String(videoMinHeight)))
			}
			if videoMaxHeight > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [maxHeight:%@]", String(videoMaxHeight))
				mandatoryConstraints.append(RTCPair(key: "maxHeight", value: String(videoMaxHeight)))
			}
			if videoMinFrameRate > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [videoMinFrameRate:%@]", String(videoMinFrameRate))
				mandatoryConstraints.append(RTCPair(key: "minFrameRate", value: String(videoMinFrameRate)))
			}
			if videoMaxFrameRate > 0 {
				NSLog("PluginGetUserMedia#call() | adding media constraint [videoMaxFrameRate:%@]", String(videoMaxFrameRate))
				mandatoryConstraints.append(RTCPair(key: "maxFrameRate", value: String(videoMaxFrameRate)))
			}

			constraints = RTCMediaConstraints(
				mandatoryConstraints: mandatoryConstraints,
				optionalConstraints: []
			)

			rtcVideoSource = self.rtcPeerConnectionFactory.videoSourceWithCapturer(rtcVideoCapturer,
				constraints: constraints
			)

			// If videoSource state is "ended" it means that constraints were not satisfied so
			// invoke the given errback.
			if (rtcVideoSource!.state == RTCSourceStateEnded) {
				NSLog("PluginGetUserMedia() | rtcVideoSource.state is 'ended', constraints not satisfied")

				errback(error: "constraints not satisfied")
				return
			}

			rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrackWithID(NSUUID().UUIDString,
				source: rtcVideoSource
			)

			rtcMediaStream.addVideoTrack(rtcVideoTrack)
		}

		if audioRequested == true {
			NSLog("PluginGetUserMedia#call() | audio requested")

			rtcAudioTrack = self.rtcPeerConnectionFactory.audioTrackWithID(NSUUID().UUIDString)

			rtcMediaStream.addAudioTrack(rtcAudioTrack!)
		}

		pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
		pluginMediaStream!.run()

		// Let the plugin store it in its dictionary.
		eventListenerForNewStream(pluginMediaStream: pluginMediaStream!)

		callback(data: [
			"stream": pluginMediaStream!.getJSON()
		])
	}
}
