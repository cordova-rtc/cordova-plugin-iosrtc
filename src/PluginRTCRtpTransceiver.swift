import Foundation

class PluginRTCRtpTransceiver : NSObject {
    var rtcRtpTransceiver: RTCRtpTransceiver?
    var eventListener: ((_ data: NSDictionary) -> Void)?

    init(
        rtcPeerConnection: RTCPeerConnection, 
        mediaStreamTrack: RTCMediaStreamTrack, 
        options: NSDictionary?, 
        eventListener: @escaping (_ data: NSDictionary) -> Void
    ) {
        NSLog("PluginRTCRtpTransceiver#init()")

		self.eventListener = eventListener

        let rtcRtpTransceiverInit = RTCRtpTransceiverInit();

        if options?.object(forKey: "direction") != nil {
            let direction = options!.object(forKey: "direction") as! String

            if direction == "inactive" {
                rtcRtpTransceiverInit.direction = RTCRtpTransceiverDirection.inactive
            } else if direction == "recvonly" {
                rtcRtpTransceiverInit.direction = RTCRtpTransceiverDirection.recvOnly
            } else if direction == "rendonly" {
                rtcRtpTransceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
            } else if direction == "sendrecv" {
                rtcRtpTransceiverInit.direction = RTCRtpTransceiverDirection.sendRecv
            } else if direction == "stopped" {
                rtcRtpTransceiverInit.direction = RTCRtpTransceiverDirection.stopped
            }
        }

        if options?.object(forKey: "streams") != nil {
            let streams = options!.object(forKey: "streams") as! [NSDictionary]
            let streamIds = streams.compactMap({$0["_id"] as! String})

            rtcRtpTransceiverInit.streamIds = streamIds
        }

        // TODO: Implement sendEncodings configuration
        if options?.object(forKey: "sendEncodings") != nil {
            NSLog("iosrtcPlugin#RTCPeerConnection_addTransceiver() | ERROR: init.sendEncodings not supported yet")
            return;
        }

        self.rtcRtpTransceiver = rtcPeerConnection.addTransceiver(with: mediaStreamTrack, init: rtcRtpTransceiverInit)

        // TODO: Implement:
		// addTransceiverOfType(mediaType)
		// addTransceiverOfType(mediaType, init)

        if self.rtcRtpTransceiver == nil {
			NSLog("PluginRTCRtpTransceiver#init() | rtcPeerConnection.addTransceiver() failed")
			return
		}

        // TODO: Notify self.eventListener
        self.eventListener!([
			"type": "new",
			"transceiver": []
		])
    }

    deinit {
		NSLog("PluginRTCRtpTransceiver#deinit()")
	}

    func stop() {
        self.rtcRtpTransceiver!.stop()
    }
}
