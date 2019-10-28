import Foundation
import AVFoundation
import ReplayKit

class PluginGetDisplayMedia {

	var rtcPeerConnectionFactory: RTCPeerConnectionFactory

	init(rtcPeerConnectionFactory: RTCPeerConnectionFactory) {
		NSLog("PluginGetDisplayMedia#init()")
		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
	}

	deinit {
		NSLog("PluginGetDisplayMedia#deinit()")
	}

	func call(
		_ constraints: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: String) -> Void,
		eventListenerForNewStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void
	) {

		NSLog("PluginGetDisplayMedia#call()")
		if #available(iOS 11.0, *) {
			
			let recorder = RPScreenRecorder.shared()
			
			if (recorder.isRecording) {
				recorder.stopRecording {(preview, error) in
					if (error != nil) {
						errback(error!.localizedDescription)
					} else {
						self.startCapture(recorder: recorder, callback: callback, errback: errback, eventListenerForNewStream: eventListenerForNewStream)
					}
				}
			} else if (recorder.isAvailable) {
				self.startCapture(recorder: recorder, callback: callback, errback: errback, eventListenerForNewStream: eventListenerForNewStream)
			} else {
				errback("Screen recorder is not available!")
			}
			
		} else {
			errback("Screen recorder is not available!")
		}
	}
	
	@available(iOS 11.0, *)
	func startCapture(
		recorder: RPScreenRecorder,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: String) -> Void,
		eventListenerForNewStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void
	) {

		let rtcMediaStream: RTCMediaStream = self.rtcPeerConnectionFactory.mediaStream(withStreamId: UUID().uuidString)
		let rtcVideoSource: RTCVideoSource = self.rtcPeerConnectionFactory.videoSource()
		let rtcVideoTrack: RTCVideoTrack = self.rtcPeerConnectionFactory.videoTrack(with: rtcVideoSource, trackId: UUID().uuidString)
	  
		rtcMediaStream.addVideoTrack(rtcVideoTrack)
	  
		let videoCapturer: RTCVideoCapturer = RTCVideoCapturer(delegate: rtcVideoSource)
	
		recorder.isMicrophoneEnabled = false
		recorder.startCapture(handler: {(sampleBuffer, bufferType, error) in
			if (bufferType == RPSampleBufferType.video) {
				self.handleSourceBuffer(
					capturer: videoCapturer,
					source: rtcVideoSource,
					sampleBuffer: sampleBuffer,
					sampleType: bufferType
				)
			}
			if (error != nil) {
				errback(error!.localizedDescription)
			}
		}) { (error) in
			if (error != nil) {
				errback(error!.localizedDescription)
			} else {
				
				var pluginMediaStream: PluginMediaStream
				pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
				
				pluginMediaStream.run()

				// Let the plugin store it in its dictionary.
				eventListenerForNewStream(pluginMediaStream)

				callback([
					"stream": pluginMediaStream.getJSON()
				])
			}
		}
	}
	
	func handleSourceBuffer(capturer:RTCVideoCapturer, source: RTCVideoSource, sampleBuffer: CMSampleBuffer, sampleType: RPSampleBufferType) {
		if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
			!CMSampleBufferDataIsReady(sampleBuffer)) {
			return;
		}
		
		let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		if (pixelBuffer == nil) {
			return;
		}
		
		let width = CVPixelBufferGetWidth(pixelBuffer!);
		let height = CVPixelBufferGetHeight(pixelBuffer!);
		
		source.adaptOutputFormat(toWidth: Int32(width/2), height: Int32(height/2), fps: 8)
		
		let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer!)
		let timeStampNs =
			CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * Float64(NSEC_PER_SEC)
		let videoFrame =  RTCVideoFrame(buffer: rtcPixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: Int64(timeStampNs))
		source.capturer(capturer, didCapture: videoFrame)
	}
}
