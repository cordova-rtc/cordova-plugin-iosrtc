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
        callback: (_ data: NSDictionary) -> Void,
        errback: (_ error: String) -> Void,
        eventListenerForNewStream: (_ pluginMediaStream: PluginMediaStream) -> Void
    ) {

        NSLog("PluginGetDisplayMedia#call()")

        var videoRequested: Bool = false

        if (constraints.object(forKey: "video") != nil) {
            videoRequested = true
        }

        var rtcMediaStream: RTCMediaStream
        var pluginMediaStream: PluginMediaStream?
        var rtcVideoTrack: RTCVideoTrack?
        var rtcVideoSource: RTCVideoSource?

        if videoRequested == true {
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case AVAuthorizationStatus.notDetermined:
                NSLog("PluginGetDisplayMedia#call() | video authorization: not determined")
            case AVAuthorizationStatus.authorized:
                NSLog("PluginGetDisplayMedia#call() | video authorization: authorized")
            case AVAuthorizationStatus.denied:
                NSLog("PluginGetDisplayMedia#call() | video authorization: denied")
                errback("video denied")
                return
            case AVAuthorizationStatus.restricted:
                NSLog("PluginGetDisplayMedia#call() | video authorization: restricted")
                errback("video restricted")
                return
            }
        }

        rtcMediaStream = self.rtcPeerConnectionFactory.mediaStream(withStreamId: UUID().uuidString)

        if videoRequested {
            
            NSLog("PluginGetDisplayMedia#call() | video requested")

            rtcVideoSource = self.rtcPeerConnectionFactory.videoSource()

            rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrack(with: rtcVideoSource!, trackId: UUID().uuidString)
            
            // Handle legacy plugin instance or video: true
            var videoConstraints : NSDictionary = [:];
            if (!(constraints.object(forKey: "video") is Bool)) {
               videoConstraints = constraints.object(forKey: "video") as! NSDictionary
            }

            NSLog("PluginGetDisplayMedia#call() | chosen video constraints: %@", videoConstraints)
            
            let videoCapturer: RTCVideoCapturer = RTCVideoCapturer(delegate: rtcVideoSource!)
            
            if #available(iOS 11.0, *){
                
                let recorder = RPScreenRecorder.shared()
                
                if(recorder.isRecording) {
                    recorder.stopRecording { [unowned self] (preview, error) in
                        // TODO
                    }
                } else if(recorder.isAvailable) {
                    recorder.startRecording{ [unowned self] (error) in
                        // TODO
                    }
                } else {
                    errback("Screen recorder is not available!")
                    return
                }
                
                
                recorder.isMicrophoneEnabled = false
                recorder.startCapture(handler: { [unowned self] (sampleBuffer, bufferType, error) in
                    if (bufferType == RPSampleBufferType.video) {
                        self.handleSourceBuffer(
                            capturer: videoCapturer,
                            source: rtcVideoSource!,
                            sampleBuffer: sampleBuffer,
                            sampleType: bufferType
                        )
                    }
                    
                    if (error != nil) {
                        
                    }
                }) 
                
            } else {

                errback("Screen recorder is not available!")
                return
            }
            

            // If videoSource state is "ended" it means that constraints were not satisfied so
            // invoke the given errback.
            if (rtcVideoSource!.state == RTCSourceState.ended) {
                NSLog("PluginGetDisplayMedia() | rtcVideoSource.state is 'ended', constraints not satisfied")

                errback("constraints not satisfied")
                return
            }

            rtcMediaStream.addVideoTrack(rtcVideoTrack!)
        }
        

        pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
        pluginMediaStream!.run()

        // Let the plugin store it in its dictionary.
        eventListenerForNewStream(pluginMediaStream!)

        callback([
            "stream": pluginMediaStream!.getJSON()
        ])
    }
    
    func handleSourceBuffer(capturer:RTCVideoCapturer, source: RTCVideoSource,sampleBuffer:CMSampleBuffer,sampleType: RPSampleBufferType) {
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
