import Foundation
import AVFoundation


@objc(iosrtcPlugin)  // This class must be accesible from Objective-C.
class iosrtcPlugin : CDVPlugin {
	// RTCPeerConnectionFactory single instance.
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory
	// Single PluginGetUserMedia instance.
	var pluginGetUserMedia: PluginGetUserMedia;
	// PluginRTCPeerConnection dictionary.
	var pluginRTCPeerConnections: [Int : PluginRTCPeerConnection] = [:]
	// PluginMediaStream dictionary.
	var pluginMediaStreams: [String : PluginMediaStream] = [:]
	// PluginMediaStreamTrack dictionary.
	var pluginMediaStreamTracks: [String : PluginMediaStreamTrack] = [:]
	// PluginMediaStreamRenderer dictionary.
	var pluginMediaStreamRenderers: [Int : PluginMediaStreamRenderer] = [:]
	// Dispatch queue for serial operations.
	let queue = dispatch_queue_create("cordova-plugin-iosrtc", DISPATCH_QUEUE_SERIAL)


	// This is just called if <param name="onload" value="true" /> in plugin.xml.
	override init(webView: UIWebView) {
		NSLog("iosrtcPlugin#init()")

		// Initialize DTLS stuff.
		RTCPeerConnectionFactory.initializeSSL()

		// Create a RTCPeerConnectionFactory.
		self.rtcPeerConnectionFactory = RTCPeerConnectionFactory()

		// Create a PluginGetUserMedia instance.
		self.pluginGetUserMedia = PluginGetUserMedia(
			rtcPeerConnectionFactory: rtcPeerConnectionFactory
		)

		super.init(webView: webView)
	}


	override func onReset() {
		NSLog("iosrtcPlugin#onReset() | doing nothing")
	}


	override func onAppTerminate() {
		NSLog("iosrtcPlugin#onAppTerminate() | doing nothing")
	}


	func new_RTCPeerConnection(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#new_RTCPeerConnection()")

		let pcId = command.argumentAtIndex(0) as! Int
		var pcConfig: NSDictionary?
		var pcConstraints: NSDictionary?

		if command.argumentAtIndex(1) != nil {
			pcConfig = command.argumentAtIndex(1) as? NSDictionary
		}

		if command.argumentAtIndex(2) != nil {
			pcConstraints = command.argumentAtIndex(2) as? NSDictionary
		}

		let pluginRTCPeerConnection = PluginRTCPeerConnection(
			rtcPeerConnectionFactory: self.rtcPeerConnectionFactory,
			pcConfig: pcConfig,
			pcConstraints: pcConstraints,
			eventListener: { (data: NSDictionary) -> Void in
				let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

				// Allow more callbacks.
				result.setKeepCallbackAsBool(true);
				self.emit(command.callbackId, result: result)
			},
			eventListenerForAddStream: self.saveMediaStream,
			eventListenerForRemoveStream: self.deleteMediaStream
		)

		// Store the pluginRTCPeerConnection into the dictionary.
		self.pluginRTCPeerConnections[pcId] = pluginRTCPeerConnection

		// Run it.
		pluginRTCPeerConnection.run()
	}


	func RTCPeerConnection_createOffer(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createOffer()")

		let pcId = command.argumentAtIndex(0) as! Int
		var options: NSDictionary?

		if command.argumentAtIndex(1) != nil {
			options = command.argumentAtIndex(1) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createOffer() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.createOffer(options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error.localizedDescription)
					)
				}
			)
		}
	}


	func RTCPeerConnection_createAnswer(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createAnswer()")

		let pcId = command.argumentAtIndex(0) as! Int
		var options: NSDictionary?

		if command.argumentAtIndex(1) != nil {
			options = command.argumentAtIndex(1) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createAnswer() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.createAnswer(options,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error.localizedDescription)
					)
				}
			)
		}
	}


	func RTCPeerConnection_setLocalDescription(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription()")

		let pcId = command.argumentAtIndex(0) as! Int
		let desc = command.argumentAtIndex(1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setLocalDescription() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.setLocalDescription(desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error.localizedDescription)
					)
				}
			)
		}
	}


	func RTCPeerConnection_setRemoteDescription(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription()")

		let pcId = command.argumentAtIndex(0) as! Int
		let desc = command.argumentAtIndex(1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_setRemoteDescription() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.setRemoteDescription(desc,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				},
				errback: { (error: NSError) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error.localizedDescription)
					)
				}
			)
		}
	}


	func RTCPeerConnection_addIceCandidate(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate()")

		let pcId = command.argumentAtIndex(0) as! Int
		let candidate = command.argumentAtIndex(1) as! NSDictionary
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addIceCandidate() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.addIceCandidate(candidate,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
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


	func RTCPeerConnection_addStream(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_addStream()")

		let pcId = command.argumentAtIndex(0) as! Int
		let streamId = command.argumentAtIndex(1) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addStream() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_addStream() | ERROR: pluginMediaStream with id=\(streamId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			if pluginRTCPeerConnection!.addStream(pluginMediaStream!) {
				self.saveMediaStream(pluginMediaStream!)
			}
		}
	}


	func RTCPeerConnection_removeStream(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_removeStream()")

		let pcId = command.argumentAtIndex(0) as! Int
		let streamId = command.argumentAtIndex(1) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeStream() | pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_removeStream() | ERROR: pluginMediaStream with id=\(streamId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.removeStream(pluginMediaStream!)
		}
	}


	func RTCPeerConnection_createDataChannel(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_createDataChannel()")

		let pcId = command.argumentAtIndex(0) as! Int
		let dcId = command.argumentAtIndex(1) as! Int
		let label = command.argumentAtIndex(2) as! String
		var options: NSDictionary?

		if command.argumentAtIndex(3) != nil {
			options = command.argumentAtIndex(3) as? NSDictionary
		}

		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_createDataChannel() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.createDataChannel(dcId,
				label: label,
				options: options,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				},
				eventListenerForBinaryMessage: { (data: NSData) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				}
			)
		}
	}


	func RTCPeerConnection_close(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_close()")

		let pcId = command.argumentAtIndex(0) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_close() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.close()
		}

		// Remove the pluginRTCPeerConnection from the dictionary.
		self.pluginRTCPeerConnections[pcId] = nil
	}


	func RTCPeerConnection_RTCDataChannel_setListener(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener()")

		let pcId = command.argumentAtIndex(0) as! Int
		let dcId = command.argumentAtIndex(1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_setListener() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.RTCDataChannel_setListener(dcId,
				eventListener: { (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				},
				eventListenerForBinaryMessage: { (data: NSData) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				}
			)
		}
	}


	func RTCPeerConnection_RTCDataChannel_sendString(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendString()")

		let pcId = command.argumentAtIndex(0) as! Int
		let dcId = command.argumentAtIndex(1) as! Int
		let data = command.argumentAtIndex(2) as! String
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendString() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.RTCDataChannel_sendString(dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	func RTCPeerConnection_RTCDataChannel_sendBinary(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary()")

		let pcId = command.argumentAtIndex(0) as! Int
		let dcId = command.argumentAtIndex(1) as! Int
		let data = command.argumentAtIndex(2) as! NSData
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_sendBinary() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.RTCDataChannel_sendBinary(dcId,
				data: data,
				callback: { (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	func RTCPeerConnection_RTCDataChannel_close(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close()")

		let pcId = command.argumentAtIndex(0) as! Int
		let dcId = command.argumentAtIndex(1) as! Int
		let pluginRTCPeerConnection = self.pluginRTCPeerConnections[pcId]

		if pluginRTCPeerConnection == nil {
			NSLog("iosrtcPlugin#RTCPeerConnection_RTCDataChannel_close() | ERROR: pluginRTCPeerConnection with pcId=\(pcId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginRTCPeerConnection!.RTCDataChannel_close(dcId)
		}
	}


	func MediaStream_setListener(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_setListener()")

		let id = command.argumentAtIndex(0) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_setListener() | ERROR: pluginMediaStream with id=\(id) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			// Set the eventListener.
			pluginMediaStream!.setListener(
				{ (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				},
				eventListenerForAddTrack: self.saveMediaStreamTrack,
				eventListenerForRemoveTrack: self.deleteMediaStreamTrack
			)
		}
	}


	func MediaStream_addTrack(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_addTrack()")

		let id = command.argumentAtIndex(0) as! String
		let trackId = command.argumentAtIndex(1) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_addTrack() | ERROR: pluginMediaStream with id=\(id) does not exist")
			return
		}

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStream_addTrack() | ERROR: pluginMediaStreamTrack with id=\(trackId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginMediaStream!.addTrack(pluginMediaStreamTrack!)
		}
	}


	func MediaStream_removeTrack(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_removeTrack()")

		let id = command.argumentAtIndex(0) as! String
		let trackId = command.argumentAtIndex(1) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[trackId]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_removeTrack() | ERROR: pluginMediaStream with id=\(id) does not exist")
			return
		}

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStream_removeTrack() | ERROR: pluginMediaStreamTrack with id=\(trackId) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginMediaStream!.removeTrack(pluginMediaStreamTrack!)
		}
	}


	func MediaStream_release(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStream_release()")

		let id = command.argumentAtIndex(0) as! String
		let pluginMediaStream = self.pluginMediaStreams[id]

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStream_release() | ERROR: pluginMediaStream with id=\(id) does not exist")
			return;
		}

		self.pluginMediaStreams[id] = nil
	}


	func MediaStreamTrack_setListener(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_setListener()")

		let id = command.argumentAtIndex(0) as! String
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_setListener() | ERROR: pluginMediaStreamTrack with id=\(id) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			// Set the eventListener.
			pluginMediaStreamTrack!.setListener(
				{ (data: NSDictionary) -> Void in
					let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

					// Allow more callbacks.
					result.setKeepCallbackAsBool(true);
					self.emit(command.callbackId, result: result)
				},
				eventListenerForEnded: { () -> Void in
					// Remove the track from the container.
					self.pluginMediaStreamTracks[pluginMediaStreamTrack!.id] = nil
				}
			)
		}
	}


	func MediaStreamTrack_setEnabled(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled()")

		let id = command.argumentAtIndex(0) as! String
		let value = command.argumentAtIndex(1) as! Bool
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_setEnabled() | ERROR: pluginMediaStreamTrack with id=\(id) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginMediaStreamTrack!.setEnabled(value)
		}
	}


	func MediaStreamTrack_stop(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamTrack_stop()")

		let id = command.argumentAtIndex(0) as! String
		let pluginMediaStreamTrack = self.pluginMediaStreamTracks[id]

		if pluginMediaStreamTrack == nil {
			NSLog("iosrtcPlugin#MediaStreamTrack_stop() | ERROR: pluginMediaStreamTrack with id=\(id) does not exist")
			return;
		}

		dispatch_async(self.queue) {
			pluginMediaStreamTrack!.stop()
		}
	}


	func new_MediaStreamRenderer(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#new_MediaStreamRenderer()")

		let id = command.argumentAtIndex(0) as! Int

		let pluginMediaStreamRenderer = PluginMediaStreamRenderer(
			webView: self.webView!,
			eventListener: { (data: NSDictionary) -> Void in
				var result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])

				// Allow more callbacks.
				result.setKeepCallbackAsBool(true);
				self.emit(command.callbackId, result: result)
			}
		)

		// Store into the dictionary.
		self.pluginMediaStreamRenderers[id] = pluginMediaStreamRenderer

		// Run it.
		pluginMediaStreamRenderer.run()
	}


	func MediaStreamRenderer_render(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_render()")

		let id = command.argumentAtIndex(0) as! Int
		let streamId = command.argumentAtIndex(1) as! String
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]
		let pluginMediaStream = self.pluginMediaStreams[streamId]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_render() | ERROR: pluginMediaStreamRenderer with id=\(id) does not exist")
			return
		}

		if pluginMediaStream == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_render() | ERROR: pluginMediaStream with id=\(streamId) does not exist")
			return;
		}

		pluginMediaStreamRenderer!.render(pluginMediaStream!)
	}


	func MediaStreamRenderer_mediaStreamChanged(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged()")

		let id = command.argumentAtIndex(0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_mediaStreamChanged() | ERROR: pluginMediaStreamRenderer with id=\(id) does not exist")
			return;
		}

		pluginMediaStreamRenderer!.mediaStreamChanged()
	}


	func MediaStreamRenderer_refresh(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_refresh()")

		let id = command.argumentAtIndex(0) as! Int
		let data = command.argumentAtIndex(1) as! NSDictionary
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_refresh() | ERROR: pluginMediaStreamRenderer with id=\(id) does not exist")
			return;
		}

		pluginMediaStreamRenderer!.refresh(data)
	}


	func MediaStreamRenderer_close(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#MediaStreamRenderer_close()")

		let id = command.argumentAtIndex(0) as! Int
		let pluginMediaStreamRenderer = self.pluginMediaStreamRenderers[id]

		if pluginMediaStreamRenderer == nil {
			NSLog("iosrtcPlugin#MediaStreamRenderer_close() | ERROR: pluginMediaStreamRenderer with id=\(id) does not exist")
			return
		}

		pluginMediaStreamRenderer!.close()

		// Remove from the dictionary.
		self.pluginMediaStreamRenderers[id] = nil
	}


	func getUserMedia(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#getUserMedia()")

		let constraints = command.argumentAtIndex(0) as! NSDictionary

		self.pluginGetUserMedia.call(constraints,
			callback: { (data: NSDictionary) -> Void in
				self.emit(command.callbackId,
					result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
				)
			},
			errback: { (error: String) -> Void in
				self.emit(command.callbackId,
					result: CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error)
				)
			},
			eventListenerForNewStream: self.saveMediaStream
		)
	}


	func getMediaDevices(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#getMediaDevices()")

		dispatch_async(self.queue) {
			PluginGetMediaDevices.call(
				{ (data: NSDictionary) -> Void in
					self.emit(command.callbackId,
						result: CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: data as [NSObject : AnyObject])
					)
				}
			)
		}
	}


	func selectAudioOutputEarpiece(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputEarpiece()")

		var error: NSError?

		AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.None, error: &error);

		if error != nil {
			NSLog("iosrtcPlugin#selectAudioOutputEarpiece() | ERROR: \(error!.localizedDescription)")
		}
	}


	func selectAudioOutputSpeaker(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#selectAudioOutputSpeaker()")

		var error: NSError?

		AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker, error: &error);

		if error != nil {
			NSLog("iosrtcPlugin#selectAudioOutputSpeaker() | ERROR: \(error!.localizedDescription)")
		}
	}


	func dump(command: CDVInvokedUrlCommand) {
		NSLog("iosrtcPlugin#dump()")

		for (id, pluginRTCPeerConnection) in self.pluginRTCPeerConnections {
			NSLog("- PluginRTCPeerConnection [id:\(id)]")
		}

		for (id, pluginMediaStream) in self.pluginMediaStreams {
			NSLog("- PluginMediaStream \(pluginMediaStream.rtcMediaStream.description)")
		}

		for (id, pluginMediaStreamTrack) in self.pluginMediaStreamTracks {
			NSLog("- PluginMediaStreamTrack [id:\(id), kind:\(pluginMediaStreamTrack.kind)]")
		}

		for (id, pluginMediaStreamRenderer) in self.pluginMediaStreamRenderers {
			NSLog("- PluginMediaStreamRenderer [id:\(id)]")
		}
	}


	/**
	 * Private API.
	 */


	private func emit(callbackId: String, result: CDVPluginResult) {
		dispatch_async(dispatch_get_main_queue()) {
			self.commandDelegate.sendPluginResult(result, callbackId: callbackId)
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
