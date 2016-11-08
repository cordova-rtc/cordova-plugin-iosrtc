import Foundation
import AVFoundation


@objc(iosrtcPlugin) // This class must be accesible from Objective-C.
class iosrtcPlugin : CDVPlugin {
    // RTCPeerConnectionFactory single instance.
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory!
	// Single PluginGetUserMedia instance.
	var pluginGetUserMedia: PluginGetUserMedia!
	// PluginRTCPeerConnection dictionary.
	var pluginRTCPeerConnections: [Int : PluginRTCPeerConnection]!
	// PluginMediaStream dictionary.
	var pluginMediaStreams: [String : PluginMediaStream]!
	// PluginMediaStreamTrack dictionary.
	var pluginMediaStreamTracks: [String : PluginMediaStreamTrack]!
	// PluginMediaStreamRenderer dictionary.
	var pluginMediaStreamRenderers: [Int : PluginMediaStreamRenderer]!
	// Dispatch queue for serial operations.
	var queue: DispatchQueue!
    
	// This is just called if <param name="onload" value="true" /> in plugin.xml.
	override func pluginInitialize() {
		NSLog("iosrtcPlugin#pluginInitialize()")

		// Make the web view transparent
		self.webView!.isOpaque = false
		self.webView!.backgroundColor = UIColor.clear

		pluginMediaStreams = [:]
		pluginMediaStreamTracks = [:]
		pluginMediaStreamRenderers = [:]
		//queue = dispatch_queue_create("cordova-plugin-iosrtc", DISPATCH_QUEUE_SERIAL)
        queue = DispatchQueue(label: "cordova-plugin-iosrtc", attributes: [], target: nil)
        pluginRTCPeerConnections = [:]

		// Initialize DTLS stuff.
		RTCPeerConnectionFactory.initializeSSL()

		// Create a RTCPeerConnectionFactory.
		self.rtcPeerConnectionFactory = RTCPeerConnectionFactory()

		// Create a PluginGetUserMedia instance.
		self.pluginGetUserMedia = PluginGetUserMedia(
			rtcPeerConnectionFactory: rtcPeerConnectionFactory
		)
        
        NSLog("iosrtcPlugin#pluginInitialize() finished")
	}


	override func onReset() {
		NSLog("iosrtcPlugin#onReset() | doing nothing")
	}


	override func onAppTerminate() {
		NSLog("iosrtcPlugin#onAppTerminate() | doing nothing")
	}

	open func new_RTCPeerConnection(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#new_RTCPeerConnection()")

		let pcId = command.argument(at: 0) as! Int
		var pcConfig: NSDictionary?
		var pcConstraints: NSDictionary?

		if command.argument(at: 1) != nil {
			pcConfig = command.argument(at: 1) as? NSDictionary
		}

		if command.argument(at: 2) != nil {
			pcConstraints = command.argument(at: 2) as? NSDictionary
		}

		let pluginRTCPeerConnection = PluginRTCPeerConnection(
			rtcPeerConnectionFactory: self.rtcPeerConnectionFactory,
			pcConfig: pcConfig,
			pcConstraints: pcConstraints,
			eventListener: { (data: NSDictionary) -> Void in
				let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

				// Allow more callbacks.
				result?.setKeepCallbackAs(true);
				self.emit(callbackId: command.callbackId, result: result!)
			},
			eventListenerForAddStream: self.saveMediaStream,
			eventListenerForRemoveStream: self.deleteMediaStream
		)

		// Store the pluginRTCPeerConnection into the dictionary.
		self.pluginRTCPeerConnections[pcId] = pluginRTCPeerConnection

		// Run it.
		pluginRTCPeerConnection.run()
	}


	open func RTCPeerConnection_createOffer(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createOffer()")

		let pcId = command.argument(at: 0) as! Int
		var options: NSDictionary?

		if command.argument(at: 1) != nil {
			options = command.argument(at: 1) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createOffer() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}
        
        self.queue.async {
		  [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.createOffer(options: options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
        }
	}


	open func RTCPeerConnection_createAnswer(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createAnswer()")

		let pcId = command.argument(at: 0) as! Int
		var options: NSDictionary?

		if command.argument(at: 1) != nil {
			options = command.argument(at: 1) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createAnswer() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}
        
		 self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.createAnswer(options: options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}


	open func RTCPeerConnection_setLocalDescription(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription()")

		let pcId = command.argument(at: 0) as! Int
		let desc = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.setLocalDescription(desc: desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}


	open func RTCPeerConnection_setRemoteDescription(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription()")

		let pcId = command.argument(at: 0) as! Int
		let desc = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.setRemoteDescription(desc: desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}


	open func RTCPeerConnection_addIceCandidate(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate()")

		let pcId = command.argument(at: 0) as! Int
		let candidate = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.addIceCandidate(candidate: candidate,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				},
				errback: { () -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR)
					)
				}
			)
		}
	}


	open func RTCPeerConnection_addStream(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_addStream()")

		let pcId = command.argument(at: 0) as! Int
		let streamId = command.argument(at: 1) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addStream() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addStream() | ERROR: pluginMediaStream with id=%@ does not exist", String(streamId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection, weak pluginMediaStream] in
			if pluginRTCPeerConnection?.addStream(pluginMediaStream: pluginMediaStream!) == true {
				self.saveMediaStream(pluginMediaStream: pluginMediaStream!)
			}
		}
	}


	open func RTCPeerConnection_removeStream(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_removeStream()")

		let pcId = command.argument(at: 0) as! Int
		let streamId = command.argument(at: 1) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeStream() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeStream() | ERROR: pluginMediaStream with id=%@ does not exist", String(streamId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection, weak pluginMediaStream] in
			pluginRTCPeerConnection?.removeStream(pluginMediaStream: pluginMediaStream!)
		}
	}


	open func RTCPeerConnection_createDataChannel(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createDataChannel()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let label = command.argument(at: 2) as! String
		var options: NSDictionary?

		if command.argument(at: 3) != nil {
			options = command.argument(at: 3) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createDataChannel() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.createDataChannel(dcId: dcId,
				label: label,
				options: options,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				},
				eventListenerForBinaryMessage: { (data: NSData) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data as Data!)

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				}
			)
		}
	}
    
    open func RTCPeerConnection_getStats(_ command: CDVInvokedUrlCommand) {
        let pcId = command.argument(at: 0) as! Int
        let trackId = command.argument(at: 1) as! String
        let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
        let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]
        
        if pluginRTCPeerConnection == nil {
            let error = String("iosrtcPlugin#RTCPeerConnection_getStats() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
            
            self.emit(callbackId: command.callbackId,
                      result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
            )
            return;
        }
        
        if pluginMediaStreamTrack == nil {
            let error = String("iosrtcPlugin#RTCPeerConnection_getStats() | ERROR: pluginMediaStreamTrack with id= /(trackId) does not exist");
            
            self.emit(callbackId: command.callbackId,
                      result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
            )
            return;
        }
        
        self.queue.async {[weak pluginRTCPeerConnection, weak pluginMediaStreamTrack] in
            pluginRTCPeerConnection?.getStats(track: pluginMediaStreamTrack,
                callback: { (data: NSDictionary) -> Void in
                    self.emit(callbackId: command.callbackId,
                              result: CDVPluginResult(status: CDVCommandStatus_OK,  messageAs: data as [NSObject : AnyObject])
                    )
                },
                errback: { (error: NSError) -> Void in
                    self.emit(callbackId: command.callbackId,
                              result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
                    )
                }
            )
        }
    }

	open func RTCPeerConnection_close(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_close()")

		let pcId = command.argument(at: 0) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_close() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			if pluginRTCPeerConnection != nil {
				pluginRTCPeerConnection!.close()
			}

			// Remove the pluginRTCPeerConnection from the dictionary.
			self.pluginRTCPeerConnections[pcId] = nil
		}
	}


	open func RTCPeerConnection_RTCDataChannel_setListener(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_setListener(dcId: dcId,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				},
				eventListenerForBinaryMessage: { (data: NSData) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data as Data!)

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				}
			)
		}
	}


	open func RTCPeerConnection_RTCDataChannel_sendString(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendString()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let data = command.argument(at: 2) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendString() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_sendString(dcId: dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	open func RTCPeerConnection_RTCDataChannel_sendBinary(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let data = command.argument(at: 2) as! NSData
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_sendBinary(dcId: dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	open func RTCPeerConnection_RTCDataChannel_close(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_close(dcId: dcId)
		}
	}


	open func RTCPeerConnection_createDTMFSender(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createDTMFSender()")

		let pcId = command.argument(at: 0) as! Int
		let dsId = command.argument(at: 1) as! Int
		let trackId = command.argument(at: 2) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createDTMFSender() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createDTMFSender() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(trackId))
			return;
		}


		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.createDTMFSender(dsId: dsId,
				track: pluginMediaStreamTrack!,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				}
			)
		}
	}


	open func RTCPeerConnection_RTCDTMFSender_insertDTMF(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDTMFSender_insertDTMF()")

		let pcId = command.argument(at: 0) as! Int
		let dsId = command.argument(at: 1) as! Int
		let tones = command.argument(at: 2) as! String
		let duration = command.argument(at: 3) as! Int
		let interToneGap = command.argument(at: 4) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDTMFSender_insertDTMF() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDTMFSender_insertDTMF(dsId: dsId,
				tones: tones,
				duration: duration,
				interToneGap: interToneGap
			)
		}
	}


	open func MediaStream_setListener(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_setListener()")

		let id = command.argument(at: 0) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_setListener() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
			return;
		}

		self.queue.async { [weak pluginMediaStream] in
			// Set the eventListener.
			pluginMediaStream?.setListener(
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				},
				eventListenerForAddTrack: self.saveMediaStreamTrack,
				eventListenerForRemoveTrack: self.deleteMediaStreamTrack
			)
		}
	}


	open func MediaStream_addTrack(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_addTrack()")

		let id = command.argument(at: 0) as! String
		let trackId = command.argument(at: 1) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_addTrack() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
			return
		}

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStream_addTrack() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(trackId))
			return;
		}

		self.queue.async { [weak pluginMediaStream, weak pluginMediaStreamTrack] in
			pluginMediaStream?.addTrack(pluginMediaStreamTrack: pluginMediaStreamTrack!)
		}
	}


	open func MediaStream_removeTrack(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_removeTrack()")

		let id = command.argument(at: 0) as! String
		let trackId = command.argument(at: 1) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_removeTrack() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
			return
		}

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStream_removeTrack() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(trackId))
			return;
		}

		self.queue.async { [weak pluginMediaStream, weak pluginMediaStreamTrack] in
			pluginMediaStream?.removeTrack(pluginMediaStreamTrack: pluginMediaStreamTrack!)
		}
	}


	open func MediaStream_release(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_release()")

		let id = command.argument(at: 0) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_release() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
			return;
		}

		self.pluginMediaStreams[id] = nil
	}


	open func MediaStreamTrack_setListener(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_setListener()")

		let id = command.argument(at: 0) as! String
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_setListener() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(id))
			return;
		}

		self.queue.async { [weak pluginMediaStreamTrack] in
			// Set the eventListener.
			pluginMediaStreamTrack?.setListener(
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result?.setKeepCallbackAs(true);
					self.emit(callbackId: command.callbackId, result: result!)
				},
				eventListenerForEnded: { () -> Void in
					// Remove the track from the container.
					self.pluginMediaStreamTracks[pluginMediaStreamTrack!.id] = nil
				}
			)
		}
	}


	open func MediaStreamTrack_setEnabled(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled()")

		let id = command.argument(at: 0) as! String
		let value = command.argument(at: 1) as! Bool
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(id))
			return;
		}

		self.queue.async {[weak pluginMediaStreamTrack] in
			pluginMediaStreamTrack?.setEnabled(value: value)
		}
	}


	open func MediaStreamTrack_stop(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_stop()")

		let id = command.argument(at: 0) as! String
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_stop() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(id))
			return;
		}

		self.queue.async { [weak pluginMediaStreamTrack] in
			pluginMediaStreamTrack?.stop()
		}
	}


	open func new_MediaStreamRenderer(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#new_MediaStreamRenderer()")

		let id = command.argument(at: 0) as! Int

		let pluginMediaStreamRenderer = PluginMediaStreamRenderer(
			webView: self.webView!,
			eventListener: { (data: NSDictionary) -> Void in
				let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])

				// Allow more callbacks.
				result?.setKeepCallbackAs(true);
				self.emit(callbackId: command.callbackId, result: result!)
			}
		)

		// Store into the dictionary.
		self.pluginMediaStreamRenderers[id] = pluginMediaStreamRenderer

		// Run it.
		pluginMediaStreamRenderer.run()
	}


	open func MediaStreamRenderer_render(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_render()")

		let id = command.argument(at: 0) as! Int
		let streamId = command.argument(at: 1) as! String
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_render() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_render() | ERROR: pluginMediaStream with id=%@ does not exist", String(streamId))
			return;
		}

		pluginMediaStreamRenderer!.render(pluginMediaStream: pluginMediaStream!)
	}


	open func MediaStreamRenderer_mediaStreamChanged(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged()")

		let id = command.argument(at: 0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return;
		}

		pluginMediaStreamRenderer!.mediaStreamChanged()
	}


	open func MediaStreamRenderer_refresh(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_refresh()")

		let id = command.argument(at: 0) as! Int
		let data = command.argument(at: 1) as! NSDictionary
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_refresh() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return;
		}

		pluginMediaStreamRenderer!.refresh(data: data)
	}


	open func MediaStreamRenderer_close(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_close()")

		let id = command.argument(at: 0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_close() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return
		}

		pluginMediaStreamRenderer!.close()

		// Remove from the dictionary.
		self.pluginMediaStreamRenderers[id] = nil
	}


	open func getUserMedia(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#getUserMedia()")

		let constraints = command.argument(at: 0) as! NSDictionary

		self.pluginGetUserMedia.call(constraints: constraints,
			callback: { (data: NSDictionary) -> Void in
				self.emit(callbackId: command.callbackId,
					result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
				)
			},
			errback: { (error: String) -> Void in
				self.emit(callbackId: command.callbackId,
					result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
				)
			},
			eventListenerForNewStream: self.saveMediaStream
		)
	}


	open func enumerateDevices(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#enumerateDevices()")

		self.queue.async {
			PluginEnumerateDevices.call(
				callback: { (data: NSDictionary) -> Void in
					self.emit(callbackId: command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	open func selectAudioOutputEarpiece(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputEarpiece()")

		do {
			try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
		} catch {
			NSLog("iosrtcPlugin#selectAudioOutputEarpiece() | ERROR: %@", String(describing: error))
		};
	}


	open func selectAudioOutputSpeaker(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputSpeaker()")

		do {
			try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
		} catch {
			NSLog("iosrtcPlugin#selectAudioOutputSpeaker() | ERROR: %@", String(describing: error))
		};
	}

	open func dump(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#dump()")

		for (id, _) in self.pluginRTCPeerConnections {
			NSLog("- PluginRTCPeerConnection [id:%@]", String(id))
		}

		for (_, pluginMediaStream) in self.pluginMediaStreams {
			NSLog("- PluginMediaStream %@", String(pluginMediaStream.rtcMediaStream.description))
		}

		for (id, pluginMediaStreamTrack) in self.pluginMediaStreamTracks {
			NSLog("- PluginMediaStreamTrack [id:%@, kind:%@]", String(id), String(pluginMediaStreamTrack.kind))
		}

		for (id, _) in self.pluginMediaStreamRenderers {
			NSLog("- PluginMediaStreamRenderer [id:%@]", String(id))
		}
	}

	/**
	 * Private API.
	 */


	private func emit(callbackId: String, result: CDVPluginResult) {
		DispatchQueue.main.async {
			self.commandDelegate!.send(result, callbackId: callbackId)
		}
	}


	private func saveMediaStream(pluginMediaStream: PluginMediaStream) {
		if self.pluginMediaStreams[pluginMediaStream.id] == nil {
			self.pluginMediaStreams[pluginMediaStream.id] = pluginMediaStream
		} else {
			return;
		}

		// Store its PluginMediaStreamTracks' into the dictionary.
		for (id, track) in pluginMediaStream.audioTracks {
			if self.pluginMediaStreamTracks[id] == nil {
				self.pluginMediaStreamTracks[id] = track
			}
		}
		for (id, track) in pluginMediaStream.videoTracks {
			if self.pluginMediaStreamTracks[id] == nil {
				self.pluginMediaStreamTracks[id] = track
			}
		}
	}


	private func deleteMediaStream(id: String) {
		self.pluginMediaStreams[id] = nil
	}


	private func saveMediaStreamTrack(pluginMediaStreamTrack: PluginMediaStreamTrack) {
		if self.pluginMediaStreamTracks[pluginMediaStreamTrack.id] == nil {
			self.pluginMediaStreamTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}
	}


	private func deleteMediaStreamTrack(id: String) {
		self.pluginMediaStreamTracks[id] = nil
	}
}
