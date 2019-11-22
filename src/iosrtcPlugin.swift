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
	// Auto selecting output speaker
	var audioOutputController: PluginRTCAudioController!


	// This is just called if <param name="onload" value="true" /> in plugin.xml.
	@objc(pluginInitialize) override func pluginInitialize() {
		NSLog("iosrtcPlugin#pluginInitialize()")
			
		// Make the web view transparent
		self.webView!.isOpaque = false
		self.webView!.backgroundColor = UIColor.clear

		pluginMediaStreams = [:]
		pluginMediaStreamTracks = [:]
		pluginMediaStreamRenderers = [:]
		queue = DispatchQueue(label: "cordova-plugin-iosrtc", attributes: [])
		pluginRTCPeerConnections = [:]

		// Initialize DTLS stuff.
		RTCInitializeSSL()
		//RTCSetMinDebugLogLevel(RTCLoggingSeverity.warning)

		// Create a RTCPeerConnectionFactory.
		self.initPeerConnectionFactory();
			
		// Create a PluginGetUserMedia instance.
		self.pluginGetUserMedia = PluginGetUserMedia(
			rtcPeerConnectionFactory: rtcPeerConnectionFactory
		)

		// Create a PluginRTCAudioController instance.
		self.audioOutputController = PluginRTCAudioController()
	}
	
	private func initPeerConnectionFactory() {
		let encoderFactory = RTCDefaultVideoEncoderFactory()
		let decoderFactory = RTCDefaultVideoDecoderFactory()
		encoderFactory.preferredCodec = getSupportedVideoEncoder(factory: encoderFactory)

		self.rtcPeerConnectionFactory = RTCPeerConnectionFactory(
			encoderFactory: encoderFactory,
			decoderFactory: decoderFactory
		)
	}
	
	private func getSupportedVideoEncoder(factory: RTCDefaultVideoEncoderFactory) -> RTCVideoCodecInfo {
		let supportedCodecs: [RTCVideoCodecInfo] = RTCDefaultVideoEncoderFactory.supportedCodecs()
		if supportedCodecs.contains(RTCVideoCodecInfo.init(name: kRTCH264CodecName)){
			return RTCVideoCodecInfo.init(name: kRTCH264CodecName)
		} else if supportedCodecs.contains(RTCVideoCodecInfo.init(name: kRTCVp9CodecName)) {
			return RTCVideoCodecInfo.init(name: kRTCVp9CodecName)
		} else {
			return RTCVideoCodecInfo.init(name: kRTCVp8CodecName)
		}
	}

	@objc(onReset) override func onReset() {
		NSLog("iosrtcPlugin#onReset() | doing nothing")
	}

	@objc(onAppTerminate) override func onAppTerminate() {
		NSLog("iosrtcPlugin#onAppTerminate() | doing nothing")
	}

	@objc(new_RTCPeerConnection:) func new_RTCPeerConnection(_ command: CDVInvokedUrlCommand) {
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
				let result = CDVPluginResult(
					status: CDVCommandStatus_OK,
					messageAs: data as? [AnyHashable: Any]
				)

				// Allow more callbacks.
				result?.setKeepCallbackAs(true);
				self.emit(command.callbackId, result: result!)
			},
			eventListenerForAddStream: self.saveMediaStream,
			eventListenerForRemoveStream: self.deleteMediaStream
		)

		// Store the pluginRTCPeerConnection into the dictionary.
		self.pluginRTCPeerConnections[pcId] = pluginRTCPeerConnection

		// Run it.
		pluginRTCPeerConnection.run()
	}

	@objc(RTCPeerConnection_createOffer:) func RTCPeerConnection_createOffer(_ command: CDVInvokedUrlCommand) {
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

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.createOffer(options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				},
				errback: { (error: Error) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_createAnswer:) func RTCPeerConnection_createAnswer(_ command: CDVInvokedUrlCommand) {
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
			pluginRTCPeerConnection?.createAnswer(options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				},
				errback: { (error: Error) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_setLocalDescription:) func RTCPeerConnection_setLocalDescription(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription()")

		let pcId = command.argument(at: 0) as! Int
		let desc = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.setLocalDescription(desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				},
				errback: { (error: Error) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_setRemoteDescription:) func RTCPeerConnection_setRemoteDescription(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription()")

		let pcId = command.argument(at: 0) as! Int
		let desc = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.setRemoteDescription(desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				},
				errback: { (error: Error) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_addIceCandidate:) func RTCPeerConnection_addIceCandidate(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate()")

		let pcId = command.argument(at: 0) as! Int
		let candidate = command.argument(at: 1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.addIceCandidate(candidate,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				},
				errback: { () -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_addStream:) func RTCPeerConnection_addStream(_ command: CDVInvokedUrlCommand) {
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
			if pluginRTCPeerConnection?.addStream(pluginMediaStream!) == true {
				self.saveMediaStream(pluginMediaStream!)
			}
		}
	}

	@objc(RTCPeerConnection_removeStream:) func RTCPeerConnection_removeStream(_ command: CDVInvokedUrlCommand) {
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
			pluginRTCPeerConnection?.removeStream(pluginMediaStream!)
		}
	}
	
	@objc(RTCPeerConnection_addTrack:) func RTCPeerConnection_addTrack(_ command: CDVInvokedUrlCommand) {
		
		let pcId = command.argument(at: 0) as! Int
		let trackId = command.argument(at: 1) as! String
		var streamIds : [String] = [];
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]
		
		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addTrack() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}
		
		if command.argument(at: 2) != nil {
			let id = command.argument(at: 2) as! String
			let pluginMediaStream = self.pluginMediaStreams[id]
			
			if pluginMediaStream == nil {
				NSLog("iosrtcPlugin#RTCPeerConnection_addTrack() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
				return;
			}
			
			let streamId = pluginMediaStream!.rtcMediaStream.streamId;
			streamIds.append(streamId)
			self.saveMediaStream(pluginMediaStream!)
		}
		
		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addTrack() | ERROR: pluginMediaStreamTrack with id=\(trackId) does not exist")
			return;
		}
		
		self.queue.async { [weak pluginRTCPeerConnection, weak pluginMediaStreamTrack] in
			if pluginRTCPeerConnection?.addTrack(pluginMediaStreamTrack!, streamIds) == true {
				self.saveMediaStreamTrack(pluginMediaStreamTrack!)
			}
		}
	}
	
	@objc(RTCPeerConnection_removeTrack:) func RTCPeerConnection_removeTrack(_ command: CDVInvokedUrlCommand) {
		let pcId = command.argument(at: 0) as! Int
		let trackId = command.argument(at: 1) as! String
		let streamId = command.argument(at: 2) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStream = self.pluginMediaStreams[streamId]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]
		
		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeTrack() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}
		
		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeTrack() | ERROR: pluginMediaStream with id=%@ does not exist", String(streamId))
			return;
		}
		
		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeTrack() | ERROR: pluginMediaStreamTrack with id=\(trackId) does not exist")
			return;
		}
		
		self.queue.async { [weak pluginRTCPeerConnection, weak pluginMediaStreamTrack] in
			pluginRTCPeerConnection?.removeTrack(pluginMediaStreamTrack!)
			// TODO remove only if not used by other stream
			self.deleteMediaStreamTrack(trackId)
		}
	}

	@objc(RTCPeerConnection_createDataChannel:) func RTCPeerConnection_createDataChannel(_ command: CDVInvokedUrlCommand) {
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
			pluginRTCPeerConnection?.createDataChannel(dcId,
				label: label,
				options: options,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				},
				eventListenerForBinaryMessage: { (data: Data) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				}
			)
		}
	}

	@objc(RTCPeerConnection_getStats:) func RTCPeerConnection_getStats(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_getStats()")

		let pcId = command.argument(at: 0) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_getStats() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		var pluginMediaStreamTrack: PluginMediaStreamTrack?

		if command.argument(at: 1) != nil {
			let trackId = command.argument(at: 1) as! String
			pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

			if pluginMediaStreamTrack == nil {
				NSLog("iosrtcPlugin#RTCPeerConnection_getStats() | ERROR: pluginMediaStreamTrack with id=\(trackId) does not exist")
				return;
			}
		}

		self.queue.async { [weak pluginRTCPeerConnection, weak pluginMediaStreamTrack] in
			pluginRTCPeerConnection?.getStats(pluginMediaStreamTrack,
				callback: { (array: [[String:Any]]) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: array as [AnyObject]
						)
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_ERROR,
							messageAs: error.localizedDescription
						)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_close:) func RTCPeerConnection_close(_ command: CDVInvokedUrlCommand) {
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

	@objc(RTCPeerConnection_RTCDataChannel_setListener:) func RTCPeerConnection_RTCDataChannel_setListener(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_setListener(dcId,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				},
				eventListenerForBinaryMessage: { (data: Data) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				}
			)
		}
	}

	@objc(RTCPeerConnection_RTCDataChannel_sendString:) func RTCPeerConnection_RTCDataChannel_sendString(_ command: CDVInvokedUrlCommand) {
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
			pluginRTCPeerConnection?.RTCDataChannel_sendString(dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_RTCDataChannel_sendBinary:) func RTCPeerConnection_RTCDataChannel_sendBinary(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let data = command.argument(at: 2) as! Data
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_sendBinary(dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				}
			)
		}
	}

	@objc(RTCPeerConnection_RTCDataChannel_close:) func RTCPeerConnection_RTCDataChannel_close(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close()")

		let pcId = command.argument(at: 0) as! Int
		let dcId = command.argument(at: 1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDataChannel_close(dcId)
		}
	}

	@objc(RTCPeerConnection_createDTMFSender:) func RTCPeerConnection_createDTMFSender(_ command: CDVInvokedUrlCommand) {
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
			pluginRTCPeerConnection?.createDTMFSender(dsId,
				track: pluginMediaStreamTrack!,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				}
			)
		}
	}

	@objc(RTCPeerConnection_RTCDTMFSender_insertDTMF:) func RTCPeerConnection_RTCDTMFSender_insertDTMF(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDTMFSender_insertDTMF()")

		let pcId = command.argument(at: 0) as! Int
		let dsId = command.argument(at: 1) as! Int
		let tones = command.argument(at: 2) as! String
		let duration = command.argument(at: 3) as! Double
		let interToneGap = command.argument(at: 4) as! Double
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDTMFSender_insertDTMF() | ERROR: pluginRTCPeerConnection with pcId=%@ does not exist", String(pcId))
			return;
		}

		self.queue.async { [weak pluginRTCPeerConnection] in
			pluginRTCPeerConnection?.RTCDTMFSender_insertDTMF(dsId,
				tones: tones,
				duration: duration,
				interToneGap: interToneGap
			)
		}
	}

	@objc(MediaStream_init:) func MediaStream_init(_ command: CDVInvokedUrlCommand) {
		
		let streamId = command.argument(at: 0) as! String
		
		if self.pluginMediaStreams[streamId] == nil {
			let rtcMediaStream : RTCMediaStream = self.rtcPeerConnectionFactory.mediaStream(withStreamId: streamId)
			let pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
			pluginMediaStream.run()
		
			self.saveMediaStream(pluginMediaStream)
		}
	}

	@objc(MediaStream_setListener:) func MediaStream_setListener(_ command: CDVInvokedUrlCommand) {
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
				{ (data: NSDictionary) -> Void in
					let result = CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				},
				eventListenerForAddTrack: self.saveMediaStreamTrack,
				eventListenerForRemoveTrack: self.deleteMediaStreamTrack
			)
		}
	}

	@objc(MediaStream_addTrack:) func MediaStream_addTrack(_ command: CDVInvokedUrlCommand) {
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
			pluginMediaStream?.addTrack(pluginMediaStreamTrack!)
		}
	}

	@objc(MediaStream_removeTrack:) func MediaStream_removeTrack(_ command: CDVInvokedUrlCommand) {
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
			pluginMediaStream?.removeTrack(pluginMediaStreamTrack!)
			
			// TODO only stop if no more pluginMediaStream attached only
			// currently pluginMediaStreamTrack can be attached to more than one pluginMediaStream
			// use track.stop() or stream.stop() to stop tracks
			//pluginMediaStreamTrack?.stop()
		}
	}

	@objc(MediaStream_release:) func MediaStream_release(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_release()")

		let id = command.argument(at: 0) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_release() | ERROR: pluginMediaStream with id=%@ does not exist", String(id))
			return;
		}

		self.pluginMediaStreams[id] = nil
	}


	@objc(MediaStreamTrack_setListener:) func MediaStreamTrack_setListener(_ command: CDVInvokedUrlCommand) {
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
				{ (data: NSDictionary) -> Void in
					let result = CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)

					// Allow more callbacks.
					result!.setKeepCallbackAs(true);
					self.emit(command.callbackId, result: result!)
				},
				eventListenerForEnded: { () -> Void in
					// Remove the track from the container.
					self.pluginMediaStreamTracks[pluginMediaStreamTrack!.id] = nil
				}
			)
		}
	}

	@objc(MediaStreamTrack_setEnabled:) func MediaStreamTrack_setEnabled(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled()")

		let id = command.argument(at: 0) as! String
		let value = command.argument(at: 1) as! Bool
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled() | ERROR: pluginMediaStreamTrack with id=%@ does not exist", String(id))
			return;
		}

		self.queue.async {[weak pluginMediaStreamTrack] in
			pluginMediaStreamTrack?.setEnabled(value)
		}
	}

	@objc(MediaStreamTrack_stop:) func MediaStreamTrack_stop(_ command: CDVInvokedUrlCommand) {
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
	
	@objc(new_MediaStreamRenderer:) func new_MediaStreamRenderer(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#new_MediaStreamRenderer()")

		let id = command.argument(at: 0) as! Int

		let pluginMediaStreamRenderer = PluginMediaStreamRenderer(
			webView: self.webView!,
			eventListener: { (data: NSDictionary) -> Void in
				let result = CDVPluginResult(
					status: CDVCommandStatus_OK,
					messageAs: data as? [AnyHashable: Any]
				)

				// Allow more callbacks.
				result?.setKeepCallbackAs(true);
				self.emit(command.callbackId, result: result!)
			}
		)

		// Store into the dictionary.
		self.pluginMediaStreamRenderers[id] = pluginMediaStreamRenderer

		// Run it.
		pluginMediaStreamRenderer.run()
	}

	@objc(MediaStreamRenderer_render:) func MediaStreamRenderer_render(_ command: CDVInvokedUrlCommand) {
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

		pluginMediaStreamRenderer!.render(pluginMediaStream!)
	}

	@objc(MediaStreamRenderer_mediaStreamChanged:) func MediaStreamRenderer_mediaStreamChanged(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged()")

		let id = command.argument(at: 0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return;
		}

		pluginMediaStreamRenderer!.mediaStreamChanged()
	}

	@objc(MediaStreamRenderer_refresh:) func MediaStreamRenderer_refresh(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_refresh()")

		let id = command.argument(at: 0) as! Int
		let data = command.argument(at: 1) as! NSDictionary
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_refresh() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return;
		}

		pluginMediaStreamRenderer!.refresh(data)
	}

	@objc(MediaStreamRenderer_save:) func MediaStreamRenderer_save(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_save()")
		
		let id = command.argument(at: 0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]
		
		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_save() | ERROR: pluginMediaStreamRenderer with id=%@ does not exist", String(id))
			return;
		}
		
		let based64 = pluginMediaStreamRenderer!.save()
		self.emit(command.callbackId,
			  result: CDVPluginResult(
				status: CDVCommandStatus_OK,
				messageAs: based64
			)
		)
	}

	@objc(MediaStreamRenderer_close:) func MediaStreamRenderer_close(_ command: CDVInvokedUrlCommand) {
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

	@objc(getUserMedia:) func getUserMedia(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#getUserMedia()")

		let constraints = command.argument(at: 0) as! NSDictionary

		self.pluginGetUserMedia.call(constraints,
			callback: { (data: NSDictionary) -> Void in
				self.emit(command.callbackId,
					result: CDVPluginResult(
						status: CDVCommandStatus_OK,
						messageAs: data as? [AnyHashable: Any]
					)
				)
			},
			errback: { (error: String) -> Void in
				self.emit(command.callbackId,
					result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
				)
			},
			eventListenerForNewStream: self.saveMediaStream
		)
	}

	@objc(enumerateDevices:) func enumerateDevices(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#enumerateDevices()")

		self.queue.async {
			PluginEnumerateDevices.call(
				{ (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(
							status: CDVCommandStatus_OK,
							messageAs: data as? [AnyHashable: Any]
						)
					)
				}
			)
		}
	}
	
	@objc(RTCRequestPermission:) func RTCRequestPermission(_ command: CDVInvokedUrlCommand) {
		DispatchQueue.main.async {
			let audioRequested: Bool = CBool(command.arguments[0] as! Bool)
			let videoRequested: Bool = CBool(command.arguments[1] as! Bool)
			var status: Bool = true
			
			if videoRequested == true {
				switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
				case AVAuthorizationStatus.notDetermined:
					NSLog("PluginGetUserMedia#call() | video authorization: not determined")
				case AVAuthorizationStatus.authorized:
					NSLog("PluginGetUserMedia#call() | video authorization: authorized")
				case AVAuthorizationStatus.denied:
					
					NSLog("PluginGetUserMedia#call() | video authorization: denied")
					status = false
				case AVAuthorizationStatus.restricted:
					NSLog("PluginGetUserMedia#call() | video authorization: restricted")
					status = false
				}
			}
			
			if audioRequested == true {
				switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
				case AVAuthorizationStatus.notDetermined:
					NSLog("PluginGetUserMedia#call() | audio authorization: not determined")
				case AVAuthorizationStatus.authorized:
					NSLog("PluginGetUserMedia#call() | audio authorization: authorized")
				case AVAuthorizationStatus.denied:
					NSLog("PluginGetUserMedia#call() | audio authorization: denied")
					status = false
				case AVAuthorizationStatus.restricted:
					NSLog("PluginGetUserMedia#call() | audio authorization: restricted")
					status = false
				}
			}
			
			if (status) {
				self.emit(command.callbackId,result: CDVPluginResult(status: CDVCommandStatus_OK))
			} else {
				self.emit(command.callbackId,result: CDVPluginResult(status: CDVCommandStatus_ERROR))
			}
		}
	}

	@objc(RTCTurnOnSpeaker:) func RTCTurnOnSpeaker(_ command: CDVInvokedUrlCommand) {
		DispatchQueue.main.async {
			let isTurnOn: Bool = CBool(command.arguments[0] as! Bool)
			PluginRTCAudioController.setOutputSpeakerIfNeed(enabled: isTurnOn)
			self.emit(command.callbackId, result: CDVPluginResult(status: CDVCommandStatus_OK))
		}
	}
	
	@objc(selectAudioOutputEarpiece:) func selectAudioOutputEarpiece(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputEarpiece()")

		PluginRTCAudioController.selectAudioOutputEarpiece()
	}

	@objc(selectAudioOutputSpeaker:) func selectAudioOutputSpeaker(_ command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputSpeaker()")
		
		PluginRTCAudioController.selectAudioOutputSpeaker()
	}

	func dump(_ command: CDVInvokedUrlCommand) {
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

	fileprivate func emit(_ callbackId: String, result: CDVPluginResult) {
		DispatchQueue.main.async {
			self.commandDelegate!.send(result, callbackId: callbackId)
		}
	}

	fileprivate func saveMediaStream(_ pluginMediaStream: PluginMediaStream) {
		if self.pluginMediaStreams[pluginMediaStream.id] == nil {
			self.pluginMediaStreams[pluginMediaStream.id] = pluginMediaStream
		} else {
			NSLog("- PluginMediaStreams already exist [id:%@]", String(pluginMediaStream.id))
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

	fileprivate func deleteMediaStream(_ id: String) {
		self.pluginMediaStreams[id] = nil
	}

	fileprivate func saveMediaStreamTrack(_ pluginMediaStreamTrack: PluginMediaStreamTrack) {
		if self.pluginMediaStreamTracks[pluginMediaStreamTrack.id] == nil {
			self.pluginMediaStreamTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}
	}

	fileprivate func deleteMediaStreamTrack(_ id: String) {
		self.pluginMediaStreamTracks[id] = nil
	}
}
