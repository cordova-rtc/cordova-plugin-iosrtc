import Foundation

class PluginRTCRtpTransceiver : NSObject {
    var rtcRtpTransceiver: RTCRtpTransceiver?
    
    init(rtcRtpTransceiver: RTCRtpTransceiver) {
        NSLog("PluginRTCRtpTransceiver#init(rtcRtpTransceiver)")
        super.init()
        
        self.rtcRtpTransceiver = rtcRtpTransceiver
    }

    init(
        rtcPeerConnection: RTCPeerConnection,
        mediaType: RTCRtpMediaType,
        options: NSDictionary?
    ) {
        NSLog("PluginRTCRtpTransceiver#init(mediaType)")
        super.init()

        let rtcRtpTransceiverInit = PluginRTCRtpTransceiver.initFromOptionsDictionary(options)

        self.rtcRtpTransceiver = rtcPeerConnection.addTransceiver(of: mediaType, init: rtcRtpTransceiverInit)

        if self.rtcRtpTransceiver == nil {
			NSLog("PluginRTCRtpTransceiver#init(mediaType) | rtcPeerConnection.addTransceiver() failed")
		}
    }

    init(
        rtcPeerConnection: RTCPeerConnection, 
        mediaStreamTrack: RTCMediaStreamTrack, 
        options: NSDictionary?
    ) {
        NSLog("PluginRTCRtpTransceiver#init(mediaStreamTrack)")
        super.init()

        let rtcRtpTransceiverInit = PluginRTCRtpTransceiver.initFromOptionsDictionary(options)

        self.rtcRtpTransceiver = rtcPeerConnection.addTransceiver(with: mediaStreamTrack, init: rtcRtpTransceiverInit)

        if self.rtcRtpTransceiver == nil {
			NSLog("PluginRTCRtpTransceiver#init(mediaStream) | rtcPeerConnection.addTransceiver() failed")
		}
    }

    /**
	 * Constructor for pc.didStartReceivingOn event.
	 */
    init(_ rtcRtpTransceiver: RTCRtpTransceiver) {
		NSLog("RTCRtpTransceiver#init()")

		self.rtcRtpTransceiver = rtcRtpTransceiver
	}

    deinit {
		NSLog("PluginRTCRtpTransceiver#deinit()")
	}

    func stop() {
        self.rtcRtpTransceiver!.stopInternal()
    }
    
    func setDirection(direction: String) {
        self.rtcRtpTransceiver?.setDirection(PluginRTCRtpTransceiver.stringToDirection(direction), error: nil)
    }
    
    static func stringToDirection(_ direction: String) -> RTCRtpTransceiverDirection {
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
    
    static func directionToString(_ direction: RTCRtpTransceiverDirection) -> String {
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

    static func initFromOptionsDictionary(_ options: NSDictionary?) -> RTCRtpTransceiverInit {
        let rtcRtpTransceiverInit = RTCRtpTransceiverInit();

        if options?.object(forKey: "direction") != nil {
            let direction = options!.object(forKey: "direction") as! String

            rtcRtpTransceiverInit.direction = PluginRTCRtpTransceiver.stringToDirection(direction)
        }

        if options?.object(forKey: "streams") != nil {
            let streams = options!.object(forKey: "streams") as! [NSDictionary]
            let streamIds = streams.compactMap({$0["_id"] as? String})

            rtcRtpTransceiverInit.streamIds = streamIds
        }

        // TODO: Implement sendEncodings configuration
        if options?.object(forKey: "sendEncodings") != nil {
            NSLog("iosrtcPlugin#RTCPeerConnection_addTransceiver() | ERROR: init.sendEncodings not supported yet")
        }

        return rtcRtpTransceiverInit
    }
}
