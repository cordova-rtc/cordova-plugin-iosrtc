import Foundation
import AVFoundation


class PluginGetUserMedia {
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory


	init(rtcPeerConnectionFactory: RTCPeerConnectionFactory) {
		NSLog("PluginGetUserMedia#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
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

		let rtcMediaStream: RTCMediaStream = self.rtcPeerConnectionFactory.mediaStreamWithLabel(NSUUID().UUIDString)
		var pluginMediaStream: PluginMediaStream?
		var rtcAudioTrack: RTCAudioTrack?
		var rtcVideoTrack: RTCVideoTrack?
		var rtcVideoCapturer: RTCVideoCapturer?
		var rtcVideoSource: RTCVideoSource?
		var videoDevice: AVCaptureDevice?

		if videoRequested == true {
			switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
			case AVAuthorizationStatus.Authorized:
				NSLog("PluginGetUserMedia#call() | video authorization: authorized")
			case AVAuthorizationStatus.Denied:
				NSLog("PluginGetUserMedia#call() | video authorization: denied")
			case AVAuthorizationStatus.Restricted:
				NSLog("PluginGetUserMedia#call() | video authorization: restricted")
			case AVAuthorizationStatus.NotDetermined:
				NSLog("PluginGetUserMedia#call() | video authorization: not determined")
			}

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
				NSLog("PluginGetUserMedia#call() | video requested (specified device id: \(videoDeviceId!))")

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

			NSLog("PluginGetUserMedia#call() | chosen video device: \(videoDevice!)")

			rtcVideoCapturer = RTCVideoCapturer(deviceName: videoDevice!.localizedName)

			rtcVideoSource = self.rtcPeerConnectionFactory.videoSourceWithCapturer(rtcVideoCapturer,
				constraints: RTCMediaConstraints()
			)

			rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrackWithID(NSUUID().UUIDString,
				source: rtcVideoSource
			)

			rtcMediaStream.addVideoTrack(rtcVideoTrack)
		}

		if audioRequested == true {
			switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) {
			case AVAuthorizationStatus.Authorized:
				NSLog("PluginGetUserMedia#call() | audio authorization: authorized")
			case AVAuthorizationStatus.Denied:
				NSLog("PluginGetUserMedia#call() | audio authorization: denied")
			case AVAuthorizationStatus.Restricted:
				NSLog("PluginGetUserMedia#call() | audio authorization: restricted")
			case AVAuthorizationStatus.NotDetermined:
				NSLog("PluginGetUserMedia#call() | audio authorization: not determined")
			}

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
