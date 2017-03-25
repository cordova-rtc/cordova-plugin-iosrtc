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
		let	videoMaxWidth = constraints.object(forKey: "videoMaxWidth") as? Int ?? 0
		let	videoMinHeight = constraints.object(forKey: "videoMinHeight") as? Int ?? 0
		let	videoMaxHeight = constraints.object(forKey: "videoMaxHeight") as? Int ?? 0
		let	videoMinFrameRate = constraints.object(forKey: "videoMinFrameRate") as? Float ?? 0.0
		let	videoMaxFrameRate = constraints.object(forKey: "videoMaxFrameRate") as? Float ?? 0.0

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

		rtcMediaStream = self.rtcPeerConnectionFactory.mediaStream(withLabel: UUID().uuidString)

		if videoRequested == true {
			// No specific video device requested.
			if videoDeviceId == nil {
				NSLog("PluginGetUserMedia#call() | video requested (device not specified)")

				for device: AVCaptureDevice in (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! Array<AVCaptureDevice>) {
					if device.position == AVCaptureDevicePosition.front {
						videoDevice = device
						break
					}
				}
			}

			// Video device specified.
			else {
				NSLog("PluginGetUserMedia#call() | video requested (specified device id: '%@')", String(videoDeviceId!))

				for device: AVCaptureDevice in (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! Array<AVCaptureDevice>) {
					if device.uniqueID == videoDeviceId {
						videoDevice = device
						break
					}
				}
			}

			if videoDevice == nil {
				NSLog("PluginGetUserMedia#call() | video requested but no suitable device found")

				errback("no suitable camera device found")
				return
			}

			NSLog("PluginGetUserMedia#call() | chosen video device: %@", String(describing: videoDevice!))

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

			rtcVideoSource = self.rtcPeerConnectionFactory.videoSource(with: rtcVideoCapturer,
				constraints: constraints
			)

			// If videoSource state is "ended" it means that constraints were not satisfied so
			// invoke the given errback.
			if (rtcVideoSource!.state == RTCSourceStateEnded) {
				NSLog("PluginGetUserMedia() | rtcVideoSource.state is 'ended', constraints not satisfied")

				errback("constraints not satisfied")
				return
			}

			rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrack(withID: UUID().uuidString,
				source: rtcVideoSource
			)

			rtcMediaStream.addVideoTrack(rtcVideoTrack)
		}

		if audioRequested == true {
			NSLog("PluginGetUserMedia#call() | audio requested")

			rtcAudioTrack = self.rtcPeerConnectionFactory.audioTrack(withID: UUID().uuidString)

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
