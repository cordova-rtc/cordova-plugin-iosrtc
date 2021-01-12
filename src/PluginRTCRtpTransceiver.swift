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

            rtcRtpTransceiverInit.direction = PluginRTCRtpTransceiver.stringToDirection(direction: direction)
        }

        if options?.object(forKey: "streams") != nil {
            let streams = options!.object(forKey: "streams") as! [NSDictionary]
            let streamIds = streams.compactMap({$0["_id"] as? String})

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
        
        // TODO: Add support for senders and receivers.
        //self.rtcRtpTransceiver?.sender
        //self.rtcRtpTransceiver?.receiver
        
        var currentDirection = RTCRtpTransceiverDirection.inactive
        self.rtcRtpTransceiver!.currentDirection(&currentDirection)

        self.eventListener!([
			"type": "state",
			"transceiver": [
                "mid": self.rtcRtpTransceiver!.mid,
                "currentDirection": PluginRTCRtpTransceiver.directionToString(direction: currentDirection),
                "direction": PluginRTCRtpTransceiver.directionToString(direction: self.rtcRtpTransceiver!.direction),
                "stopped": self.rtcRtpTransceiver!.isStopped
            ]
		])
    }

    deinit {
		NSLog("PluginRTCRtpTransceiver#deinit()")
	}

    func stop() {
        self.rtcRtpTransceiver!.stop()
        
        self.eventListener!([
            "type": "state",
            "transceiver": [
                "direction": PluginRTCRtpTransceiver.directionToString(direction: self.rtcRtpTransceiver!.direction),
                "stopped": self.rtcRtpTransceiver!.isStopped
            ]
        ])
    }
    
    func setDirection(direction: String) {
        self.rtcRtpTransceiver!.direction = PluginRTCRtpTransceiver.stringToDirection(direction: direction)
        
        self.eventListener!([
            "type": "state",
            "transceiver": [
                "direction": PluginRTCRtpTransceiver.directionToString(direction: self.rtcRtpTransceiver!.direction),
                "stopped": self.rtcRtpTransceiver!.isStopped
            ]
        ])
    }
    
    static func stringToDirection(direction: String) -> RTCRtpTransceiverDirection {
        switch direction {
        case "inactive":
            return RTCRtpTransceiverDirection.inactive
        case "recvonly":
            return RTCRtpTransceiverDirection.recvOnly
        case "sendonly":
            return RTCRtpTransceiverDirection.sendOnly
        case "sendrecv":
            return RTCRtpTransceiverDirection.sendRecv
        case "stopped":
            return RTCRtpTransceiverDirection.stopped
        default:
            NSLog("PluginRTCRtpTransceiver#stringToDirection() | Unrecognized direction value: @%", direction)
            return RTCRtpTransceiverDirection.inactive
        }
    }
    
    static func directionToString(direction: RTCRtpTransceiverDirection) -> String {
        switch direction {
        case RTCRtpTransceiverDirection.inactive:
            return "inactive"
        case RTCRtpTransceiverDirection.recvOnly:
            return "recvonly"
        case RTCRtpTransceiverDirection.sendOnly:
            return "sendonly"
        case RTCRtpTransceiverDirection.sendRecv:
            return "sendrecv"
        case RTCRtpTransceiverDirection.stopped:
            return "stopped"
        }
    }
}
