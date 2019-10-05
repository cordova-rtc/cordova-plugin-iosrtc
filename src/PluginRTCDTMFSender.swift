import Foundation


class PluginRTCDTMFSender : NSObject {
    var rtcRtpSender: RTCRtpSender?
    var eventListener: ((_ data: NSDictionary) -> Void)?

    /**
     * Constructor for pc.createDTMFSender().
     */
    init(
        rtcPeerConnection: RTCPeerConnection,
        track: RTCMediaStreamTrack,
        streamId: String,
        eventListener: @escaping (_ data: NSDictionary) -> Void
    ) {
        NSLog("PluginRTCDTMFSender#init()")

        let streamIds = [streamId]
        self.eventListener = eventListener
        //self.rtcRtpSender = rtcPeerConnection.add(track, streamIds: streamIds);

        if self.rtcRtpSender == nil {
            NSLog("PluginRTCDTMFSender#init() | rtcPeerConnection.createDTMFSenderForTrack() failed")
            return
        }
    }

    deinit {
        NSLog("PluginRTCDTMFSender#deinit()")
    }

    func run() {
        NSLog("PluginRTCDTMFSender#run()")
    }

    func insertDTMF(_ tones: String, duration: TimeInterval, interToneGap: TimeInterval) {
        NSLog("PluginRTCDTMFSender#insertDTMF()")

        
        //let dtmfSender = self.rtcRtpSender?.dtmfSender
        //let result = dtmfSender!.insertDtmf(tones, duration: duration, interToneGap: interToneGap)
        let result = false;
        
        if !result {
            NSLog("PluginRTCDTMFSender#indertDTMF() | RTCDTMFSender#indertDTMF() failed")
        }
    }

    /**
     * Methods inherited from RTCDTMFSenderDelegate.
     */
    func toneChange(_ tone: String) {
        NSLog("PluginRTCDTMFSender | tone change [tone:%@]", tone)

        if self.eventListener != nil {
            self.eventListener!([
                "type": "tonechange",
                "tone": tone
            ])
        }
    }
}
