/**
 * Expose the RTCPeerConnection class.
 */
module.exports = RTCPeerConnection;


/**
 * Dependencies.
 */
var 
	debug = require('debug')('iosrtc:RTCPeerConnection'),
	debugerror = require('debug')('iosrtc:ERROR:RTCPeerConnection'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget'),
	RTCSessionDescription = require('./RTCSessionDescription'),
	RTCIceCandidate = require('./RTCIceCandidate'),
	RTCDataChannel = require('./RTCDataChannel'),
	RTCDTMFSender = require('./RTCDTMFSender'),
	RTCStatsResponse = require('./RTCStatsResponse'),
	RTCStatsReport = require('./RTCStatsReport'),
	MediaStream = require('./MediaStream'),
	MediaStreamTrack = require('./MediaStreamTrack'),
	Errors = require('./Errors');

debugerror.log = console.warn.bind(console);

function deprecateWarning(method, newMethod) {
	if (!newMethod) {
		console.warn(method + ' is deprecated.');
	} else {
		console.warn(method + ' method is deprecated, use ' + newMethod + ' instead.');	
	}
}

function RTCPeerConnection(pcConfig, pcConstraints) {
	debug('new() | [pcConfig:%o, pcConstraints:%o]', pcConfig, pcConstraints);

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Restore corrupted RTCPeerConnection.prototype
	// TODO find why webrtc-adapter prevent events onnegotiationneeded to be trigger.
	// Object.defineProperties(this, RTCPeerConnection.prototype_descriptor);

	// Fix webrtc-adapter bad SHIM on addTrack causing error when original does support multiple streams.
	// NotSupportedError: The adapter.js addTrack polyfill only supports a single stream which is associated with the specified track.
	Object.defineProperty(this, 'addTrack', RTCPeerConnection.prototype_descriptor.addTrack);
	Object.defineProperty(this, 'getLocalStreams', RTCPeerConnection.prototype_descriptor.getLocalStreams);
	
	// Public atributes.
	this._localDescription = null;
	this.remoteDescription = null;
	this.signalingState = 'stable';
	this.iceGatheringState = 'new';
	this.iceConnectionState = 'new';
	this.pcConfig = fixPcConfig(pcConfig);

	// Private attributes.
	this.pcId = randomNumber();
	this.localStreams = {};
	this.remoteStreams = {};

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'new_RTCPeerConnection', [this.pcId, this.pcConfig, pcConstraints]);
}

RTCPeerConnection.prototype = Object.create(EventTarget.prototype);
RTCPeerConnection.prototype.constructor = RTCPeerConnection;

Object.defineProperties(RTCPeerConnection.prototype, {
	'localDescription': { 
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		get: function() { 
			return this._localDescription;
		}
	},
	'connectionState': { 
		get: function() { 
			return this.iceConnectionState;
		} 
	},
	'onicecandidate': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('icecandidate', callback);
		}
	},
	'onaddstream': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('addstream', callback);
		}
	},
	'oniceconnectionstatechange': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('iceconnectionstatechange', callback);
		}
	},
	'onnegotiationneeded': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('negotiationneeded', callback);
		}
	}
});

RTCPeerConnection.prototype.createOffer = function (options) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createOffer', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return;
	}

	debug('createOffer() [options:%o]', options);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			var desc = new RTCSessionDescription(data);

			debug('createOffer() | success [desc:%o]', desc);
			resolve(desc);
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('createOffer() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createOffer', [self.pcId, options]);
	});
};


RTCPeerConnection.prototype.createAnswer = function (options) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createAnswer', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return;
	}

	debug('createAnswer() [options:%o]', options);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			var desc = new RTCSessionDescription(data);

			debug('createAnswer() | success [desc:%o]', desc);
			resolve(desc);
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('createAnswer() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createAnswer', [self.pcId, options]);
	});
};

RTCPeerConnection.prototype.setLocalDescription = function (desc) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.setLocalDescription', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other 
	// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary, 
	// so you don't have to instantiate an RTCSessionDescription yourself.""
	// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
	// Still we do instnanciate RTCSessionDescription, so internal object is used properly.

	if (!(desc instanceof RTCSessionDescription)) {
		desc = new RTCSessionDescription(desc);
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('setLocalDescription() | success');
			// Update localDescription.
			self._localDescription = new RTCSessionDescription(data);
			resolve();
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('setLocalDescription() | failure: %s', error);
			reject(new Errors.InvalidSessionDescriptionError('setLocalDescription() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setLocalDescription', [self.pcId, desc]);
	});
};

RTCPeerConnection.prototype.setRemoteDescription = function (desc) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.setRemoteDescription', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	debug('setRemoteDescription() [desc:%o]', desc);

	// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other 
	// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary, 
	// so you don't have to instantiate an RTCSessionDescription yourself.""
	// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
	// Still we do instnanciate RTCSessionDescription so internal object is used properly.

	if (!(desc instanceof RTCSessionDescription)) {
		desc = new RTCSessionDescription(desc);
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('setRemoteDescription() | success');
			// Update remoteDescription.
			self.remoteDescription = new RTCSessionDescription(data);
			resolve();
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('setRemoteDescription() | failure: %s', error);
			reject(new Errors.InvalidSessionDescriptionError('setRemoteDescription() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setRemoteDescription', [self.pcId, desc]);
	});
};

RTCPeerConnection.prototype.addIceCandidate = function (candidate) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.addIceCandidate', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	debug('addIceCandidate() | [candidate:%o]', candidate);

	if (typeof candidate !== 'object') {
		return new Promise(function (resolve, reject) {
			reject(new global.DOMException('addIceCandidate() must be called with a RTCIceCandidate instance or RTCIceCandidateInit object as argument'));
		});
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('addIceCandidate() | success');
			// Update remoteDescription.
			if (self.remoteDescription && data.remoteDescription) {
				self.remoteDescription.type = data.remoteDescription.type;
				self.remoteDescription.sdp = data.remoteDescription.sdp;
			} else if (data.remoteDescription) {
				self.remoteDescription = new RTCSessionDescription(data.remoteDescription);
			}
			resolve();
		}

		function onResultError() {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('addIceCandidate() | failure');
			reject(new global.DOMException('addIceCandidate() failed'));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_addIceCandidate', [self.pcId, candidate]);
	});
};

RTCPeerConnection.prototype.getConfiguration = function () {
	debug('getConfiguration()');

	return this.pcConfig;
};

RTCPeerConnection.prototype.getLocalStreams = function () {
	debug('getLocalStreams()');
	deprecateWarning('getLocalStreams', 'getSenders');

	var streams = [],
		id;

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			streams.push(this.localStreams[id]);
		}
	}

	return streams;
};


RTCPeerConnection.prototype.getRemoteStreams = function () {
	debug('getRemoteStreams()');
	deprecateWarning('getRemoteStreams', 'getReceivers');

	var streams = [],
		id;

	for (id in this.remoteStreams) {
		if (this.remoteStreams.hasOwnProperty(id)) {
			streams.push(this.remoteStreams[id]);
		}
	}

	return streams;
};

RTCPeerConnection.prototype.getReceivers = function () {
	var tracks = [],
		id;

	for (id in this.remoteStreams) {
		if (this.remoteStreams.hasOwnProperty(id)) {
			tracks = tracks.concat(this.remoteStreams[id].getTracks());
		}
	}

	return tracks;
};

RTCPeerConnection.prototype.getSenders = function () {
	var tracks = [],
		id;

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			tracks = tracks.concat(this.localStreams[id].getTracks());
		}
	}

	return tracks;
};

RTCPeerConnection.prototype.addTrack = function (track, stream) {
	var id;

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	// Add localStreams if missing
	// Disable to match browser behavior
	//stream = stream || Object.values(this.localStreams)[0] || new MediaStream();

	// Fix webrtc-adapter bad SHIM on addStream
	if (stream) {
		if (!(stream instanceof MediaStream.originalMediaStream)) {
			throw new Error('addTrack() must be called with a MediaStream instance as argument');
		}

		if (!this.localStreams[stream.id]) {
			this.localStreams[stream.id] = stream;
		}

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
	}

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			// Target provided stream argument or first added stream to group track
			if (!stream || (stream && stream.id === id)) { 
				stream = this.localStreams[id];
				stream.addTrack(track);
				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [this.pcId, track.id, id]);
				break;
			}
		}
	}

	// No Stream matched add track without stream
	if (!stream) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [this.pcId, track.id, null]);
	}
};

RTCPeerConnection.prototype.removeTrack = function (track) {
	var id,
		stream,
		hasTrack;

	function matchLocalTrack(localTrack) {
		return localTrack.id === track.id;
	}

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			// Check if track is belong to stream
			hasTrack = (this.localStreams[id].getTracks().filter(matchLocalTrack).length > 0);

			if (hasTrack) {
				stream = this.localStreams[id];
				stream.removeTrack(track);

				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeTrack', [this.pcId, track.id, stream.id]);
				break;
			}
		}
	}
};

RTCPeerConnection.prototype.getStreamById = function (id) {
	debug('getStreamById()');

	return this.localStreams[id] || this.remoteStreams[id] || null;
};


RTCPeerConnection.prototype.addStream = function (stream) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('addStream()');

	if (!(stream instanceof MediaStream.originalMediaStream)) {
		throw new Error('addStream() must be called with a MediaStream instance as argument');
	}

	if (this.localStreams[stream.id]) {
		debugerror('addStream() | given stream already in present in local streams');
		return;
	}

	this.localStreams[stream.id] = stream;

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
};


RTCPeerConnection.prototype.removeStream = function (stream) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('removeStream()');

	if (!(stream instanceof MediaStream.originalMediaStream)) {
		throw new Error('removeStream() must be called with a MediaStream instance as argument');
	}

	if (!this.localStreams[stream.id]) {
		debugerror('removeStream() | given stream not present in local streams');
		return;
	}

	delete this.localStreams[stream.id];

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeStream', [this.pcId, stream.id]);
};


RTCPeerConnection.prototype.createDataChannel = function (label, options) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('createDataChannel() [label:%s, options:%o]', label, options);

	return new RTCDataChannel(this, label, options);
};


RTCPeerConnection.prototype.createDTMFSender = function (track) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('createDTMFSender() [track:%o]', track);

	return new RTCDTMFSender(this, track);
};

RTCPeerConnection.prototype.getStats = function (selector) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.getStats', arguments);

	var self = this;

	if (selector && !(selector instanceof MediaStreamTrack)) {
		throw new Error('getStats() must be called with null or a valid MediaStreamTrack instance as argument');
	}

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('getStats() [selector:%o]', selector);

	return new Promise(function (resolve, reject) {
		function onResultOK(array) {
			if (isClosed.call(self)) {
				return;
			}

			var res = [];
			array.forEach(function (stat) {
				res.push(new RTCStatsReport(stat));
			});
			resolve(new RTCStatsResponse(res));
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('getStats() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_getStats', [self.pcId, selector ? selector.id : null]);
	});
};

RTCPeerConnection.prototype.close = function () {
	if (isClosed.call(this)) {
		return;
	}

	debug('close()');

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_close', [this.pcId]);
};

// Save current RTCPeerConnection.prototype
RTCPeerConnection.prototype_descriptor = Object.getOwnPropertyDescriptors(RTCPeerConnection.prototype);

/**
 * Private API.
 */
function fixPcConfig(pcConfig) {
	if (!pcConfig) {
		return {
			iceServers: []
		};
	}

	var iceServers = pcConfig.iceServers,
		i, len, iceServer;

	if (!Array.isArray(iceServers)) {
		pcConfig.iceServers = [];
		return pcConfig;
	}

	for (i = 0, len = iceServers.length; i < len; i++) {
		iceServer = iceServers[i];

		// THe Objective-C wrapper of WebRTC is old and does not implement .urls.
		if (iceServer.url) {
			continue;
		} else if (Array.isArray(iceServer.urls)) {
			iceServer.url = iceServer.urls[0];
		} else if (typeof iceServer.urls === 'string') {
			iceServer.url = iceServer.urls;
		}
	}

	return pcConfig;
}


function isClosed() {
	return this.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		self = this,
		event = new Event(type),
		stream,
		dataChannel,
		id;

	Object.defineProperty(event, 'target', {value: self, enumerable: true});

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'signalingstatechange':
			this.signalingState = data.signalingState;
			break;

		case 'icegatheringstatechange':
			this.iceGatheringState = data.iceGatheringState;
			break;

		case 'iceconnectionstatechange':
			this.iceConnectionState = data.iceConnectionState;

			// Emit "connected" on remote streams if ICE connected.
			if (data.iceConnectionState === 'connected') {
				for (id in this.remoteStreams) {
					if (this.remoteStreams.hasOwnProperty(id)) {
						this.remoteStreams[id].emitConnected();
					}
				}
			}
			break;

		case 'icecandidate':
			if (data.candidate) {
				event.candidate = new RTCIceCandidate(data.candidate);
			} else {
				event.candidate = null;
			}
			// Update _localDescription.
			if (this._localDescription) {
				this._localDescription.type = data.localDescription.type;
				this._localDescription.sdp = data.localDescription.sdp;
			} else {
				this._localDescription = new RTCSessionDescription(data);
			}
			break;

		case 'negotiationneeded':
			break;

		case 'addtrack':
			event.track = data.track;
			break;

		case 'addstream':
			stream = MediaStream.create(data.stream);
			event.stream = stream;

			// Append to the remote streams.
			this.remoteStreams[stream.id] = stream;

			// Emit "connected" on the stream if ICE connected.
			if (this.iceConnectionState === 'connected' || this.iceConnectionState === 'completed') {
				stream.emitConnected();
			}
			break;

		case 'removestream':
			stream = this.remoteStreams[data.streamId];
			event.stream = stream;

			// Remove from the remote streams.
			delete this.remoteStreams[stream.id];
			break;

		case 'datachannel':
			dataChannel = new RTCDataChannel(this, null, null, data.channel);
			event.channel = dataChannel;
			break;
	}

	this.dispatchEvent(event);
}
