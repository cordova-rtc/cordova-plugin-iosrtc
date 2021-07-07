import Foundation

class PluginRTCRtpTransceiver : NSObject {
    // NOTE: ID used to reference this native transceiver from JS.
    var id: Int
    var rtcRtpTransceiver: RTCRtpTransceiver?
	var pluginRTCRtpReceiver: PluginRTCRtpReceiver?
	var pluginRTCRtpSender: PluginRTCRtpSender?
    
    init(_ rtcRtpTransceiver: RTCRtpTransceiver) {
        NSLog("PluginRTCRtpTransceiver#init(rtcRtpTransceiver)")
        
        // TODO: Using random ID could cause conflicts.
        self.id = Int.random(in: 0...10000)
        self.rtcRtpTransceiver = rtcRtpTransceiver
		self.pluginRTCRtpSender = PluginRTCRtpSender(rtcRtpTransceiver.sender, 0)
		self.pluginRTCRtpReceiver = PluginRTCRtpReceiver(rtcRtpTransceiver.receiver, 0)
        
        super.init()
    }

    init(
        rtcPeerConnection: RTCPeerConnection,
        mediaType: RTCRtpMediaType,
        options: NSDictionary?,
		transceiverId: Int,
		senderId: Int,
		receiverId: Int
    ) {
        NSLog("PluginRTCRtpTransceiver#init(mediaType)")
        
        let rtcRtpTransceiverInit = PluginRTCRtpTransceiver.initFromOptionsDictionary(options)

		self.id = transceiverId != 0 ? transceiverId : Int.random(in: 0...10000)
        self.rtcRtpTransceiver = rtcPeerConnection.addTransceiver(of: mediaType, init: rtcRtpTransceiverInit)

        if self.rtcRtpTransceiver == nil {
			NSLog("PluginRTCRtpTransceiver#init(mediaType) | rtcPeerConnection.addTransceiver() failed")
		} else {
			if self.rtcRtpTransceiver?.sender != nil {
				self.pluginRTCRtpSender = PluginRTCRtpSender(self.rtcRtpTransceiver!.sender, senderId)
			}
			if self.rtcRtpTransceiver?.receiver != nil {
				self.pluginRTCRtpReceiver = PluginRTCRtpReceiver(self.rtcRtpTransceiver!.receiver, receiverId)
			}
		}
        
        super.init()
    }

    init(
        rtcPeerConnection: RTCPeerConnection, 
        mediaStreamTrack: RTCMediaStreamTrack, 
        options: NSDictionary?,
		transceiverId: Int,
		senderId: Int,
		receiverId: Int
    ) {
        NSLog("PluginRTCRtpTransceiver#init(mediaStreamTrack)")
        
        let rtcRtpTransceiverInit = PluginRTCRtpTransceiver.initFromOptionsDictionary(options)

		self.id = transceiverId != 0 ? transceiverId : Int.random(in: 0...10000)
        self.rtcRtpTransceiver = rtcPeerConnection.addTransceiver(with: mediaStreamTrack, init: rtcRtpTransceiverInit)

        if self.rtcRtpTransceiver == nil {
			NSLog("PluginRTCRtpTransceiver#init(mediaStream) | rtcPeerConnection.addTransceiver() failed")
		} else {
			if self.rtcRtpTransceiver?.sender != nil {
				self.pluginRTCRtpSender = PluginRTCRtpSender(self.rtcRtpTransceiver!.sender, senderId)
			}
			if self.rtcRtpTransceiver?.receiver != nil {
				self.pluginRTCRtpReceiver = PluginRTCRtpReceiver(self.rtcRtpTransceiver!.receiver, receiverId)
			}
		}

        super.init()
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
            let streamIds = options!.object(forKey: "streams") as! [String]

            rtcRtpTransceiverInit.streamIds = streamIds
        }

        if options?.object(forKey: "sendEncodings") != nil {
            let encodings = options!.object(forKey: "sendEncodings") as! [NSDictionary]
            rtcRtpTransceiverInit.sendEncodings = encodings.map({ (encoding: NSDictionary) -> RTCRtpEncodingParameters in
                let encodingParameters = RTCRtpEncodingParameters()
                encodingParameters.isActive = encoding["active"] as? Bool ?? true
                encodingParameters.maxBitrateBps = encoding["maxBitrate"] as? NSNumber
                encodingParameters.maxFramerate = encoding["maxFramerate"] as? NSNumber
                encodingParameters.rid = encoding["rid"] as? String
                encodingParameters.scaleResolutionDownBy = encoding["scaleResolutionDownBy"] as? NSNumber
                return encodingParameters
            })
        }

        return rtcRtpTransceiverInit
    }

	func getJSON() -> NSDictionary {
		var currentDirection = RTCRtpTransceiverDirection.inactive
		self.rtcRtpTransceiver?.currentDirection(&currentDirection)

		return [
			"id": self.id,
			"mid": self.rtcRtpTransceiver?.mid,
			"stopped": self.rtcRtpTransceiver?.isStopped,
			"direction": PluginRTCRtpTransceiver.directionToString(rtcRtpTransceiver!.direction),
			"currentDirection": PluginRTCRtpTransceiver.directionToString(currentDirection),
			"receiver": self.pluginRTCRtpReceiver?.getJSON(),
			"sender": self.pluginRTCRtpSender?.getJSON()
		]
	}
}
