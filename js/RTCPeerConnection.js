/**
 * Expose the RTCPeerConnection class.
 */
module.exports = RTCPeerConnection;

/**
 * Dependencies.
 */
var debug = require('debug')('iosrtc:RTCPeerConnection'),
	debugerror = require('debug')('iosrtc:ERROR:RTCPeerConnection'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true }),
	EventTarget = require('./EventTarget'),
	RTCSessionDescription = require('./RTCSessionDescription'),
	RTCIceCandidate = require('./RTCIceCandidate'),
	RTCDataChannel = require('./RTCDataChannel'),
	RTCDTMFSender = require('./RTCDTMFSender'),
	RTCRtpReceiver = require('./RTCRtpReceiver'),
	RTCRtpSender = require('./RTCRtpSender'),
	{ RTCRtpTransceiver, addTransceiverToPeerConnection } = require('./RTCRtpTransceiver'),
	RTCStatsReport = require('./RTCStatsReport'),
	MediaStream = require('./MediaStream'),
	{ MediaStreamTrack, newMediaStreamTrackId } = require('./MediaStreamTrack'),
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
	// NotSupportedError: The adapter.js addTrack, addStream polyfill only supports a single stream which is associated with the specified track.
	Object.defineProperty(this, 'addTrack', RTCPeerConnection.prototype_descriptor.addTrack);
	Object.defineProperty(this, 'addStream', RTCPeerConnection.prototype_descriptor.addStream);
	Object.defineProperty(
		this,
		'getLocalStreams',
		RTCPeerConnection.prototype_descriptor.getLocalStreams
	);
	Object.defineProperty(
		this,
		'addTransceiver',
		RTCPeerConnection.prototype_descriptor.addTransceiver
	);
	Object.defineProperty(
		this,
		'getOrCreateTrack',
		RTCPeerConnection.prototype_descriptor.getOrCreateTrack
	);

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

	this.tracks = {};
	this.transceivers = [];

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'new_RTCPeerConnection', [
		this.pcId,
		this.pcConfig,
		pcConstraints
	]);
}

RTCPeerConnection.prototype = Object.create(EventTarget.prototype);
RTCPeerConnection.prototype.constructor = RTCPeerConnection;

Object.defineProperties(RTCPeerConnection.prototype, {
	localDescription: {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		get: function () {
			return this._localDescription;
		}
	},
	connectionState: {
		get: function () {
			return this.iceConnectionState;
		}
	},
	onicecandidate: {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('icecandidate', callback);
		}
	},
	onaddstream: {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('addstream', callback);
		}
	},
	ontrack: {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('track', callback);
		}
	},
	oniceconnectionstatechange: {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('iceconnectionstatechange', callback);
		}
	},
	onnegotiationneeded: {
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

			if (data.transceivers) {
				self.updateTransceiversState(data.transceivers);
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

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createOffer', [
			self.pcId,
			options
		]);
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

			if (data.transceivers) {
				self.updateTransceiversState(data.transceivers);
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

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createAnswer', [
			self.pcId,
			options
		]);
	});
};

RTCPeerConnection.prototype.setLocalDescription = function (desc) {
	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage(
		'RTCPeerConnection.prototype.setLocalDescription',
		arguments
	);

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

			if (data.transceivers) {
				self.updateTransceiversState(data.transceivers);
			}

			debug('setLocalDescription() | success');
			// Update localDescription.
			self._localDescription = data.type === '' ? null : new RTCSessionDescription(data);
			resolve();
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('setLocalDescription() | failure: %s', error);
			reject(
				new Errors.InvalidSessionDescriptionError('setLocalDescription() failed: ' + error)
			);
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setLocalDescription', [
			self.pcId,
			desc
		]);
	});
};

RTCPeerConnection.prototype.setRemoteDescription = function (desc) {
	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage(
		'RTCPeerConnection.prototype.setRemoteDescription',
		arguments
	);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	debug('setRemoteDescription() [desc:%o]', desc);

	// Remove extmap-allow-mixed sdp header
	if (desc && desc.sdp && desc.sdp.indexOf('\na=extmap-allow-mixed') !== -1) {
		desc = new RTCSessionDescription({
			type: desc.type,
			sdp: desc.sdp
				.split('\n')
				.filter((line) => {
					return line.trim() !== 'a=extmap-allow-mixed';
				})
				.join('\n')
		});
	}

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

			if (data.transceivers) {
				self.updateTransceiversState(data.transceivers);
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
			reject(
				new Errors.InvalidSessionDescriptionError('setRemoteDescription() failed: ' + error)
			);
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setRemoteDescription', [
			self.pcId,
			desc
		]);
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
			reject(
				new global.DOMException(
					'addIceCandidate() must be called with a RTCIceCandidate instance or RTCIceCandidateInit object as argument'
				)
			);
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

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_addIceCandidate', [
			self.pcId,
			candidate
		]);
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
	return this.getTransceivers()
		.filter((transceiver) => !transceiver.stopped)
		.map((transceiver) => transceiver.receiver);
};

RTCPeerConnection.prototype.getSenders = function () {
	return this.getTransceivers()
		.filter((transceiver) => !transceiver.stopped)
		.map((transceiver) => transceiver.sender);
};

RTCPeerConnection.prototype.getTransceivers = function () {
	return this.transceivers;
};

RTCPeerConnection.prototype.addTrack = function (track, ...streams) {
	var stream = streams[0];

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	// Add localStreams if missing
	// Disable to match browser behavior
	//stream = stream || Object.values(this.localStreams)[0] || new MediaStream();

	// Fix webrtc-adapter bad SHIM on addStream
	if (stream) {
		this.addStream(stream);
	}

	var transceiver = new RTCRtpTransceiver(this, {
		sender: new RTCRtpSender(this, {
			track: track
		}),
		receiver: new RTCRtpReceiver(this),
		direction: 'sendrecv',
		currentDirection: null,
		mid: null
	});

	for (var streamId in this.localStreams) {
		if (this.localStreams.hasOwnProperty(streamId)) {
			// Target provided stream argument or first added stream to group track
			if (!stream || (stream && stream.id === streamId)) {
				stream = this.localStreams[streamId];
				stream.addTrack(track);
				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [
					this.pcId,
					track.id,
					transceiver._id,
					transceiver.receiver._id,
					transceiver.sender._id,
					streamId
				]);
				break;
			}
		}
	}

	// No Stream matched add track without stream
	if (!stream) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [
			this.pcId,
			track.id,
			transceiver._id,
			transceiver.receiver._id,
			transceiver.sender._id,
			null
		]);
	}

	this.getOrCreateTrack(track);

	this.transceivers.push(transceiver);

	return transceiver.sender;
};

RTCPeerConnection.prototype.removeTrack = function (sender) {
	var id, track, stream, hasTrack;

	if (!(sender instanceof RTCRtpSender)) {
		throw new Error('removeTrack() must be called with a RTCRtpSender instance as argument');
	}

	track = sender.track;

	// No sender track found
	if (!track) {
		return;
	}

	function matchLocalTrack(localTrack) {
		return localTrack.id === track.id;
	}

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			// Check if track is belong to stream
			hasTrack = this.localStreams[id].getTracks().filter(matchLocalTrack).length > 0;

			if (hasTrack) {
				stream = this.localStreams[id];
				stream.removeTrack(track);
				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeTrack', [
					this.pcId,
					sender._id
				]);
				delete this.tracks[track.id];
				break;
			}
		}
	}

	// No Stream matched remove track without stream
	if (!stream) {
		for (id in this.tracks) {
			if (this.tracks.hasOwnProperty(id)) {
				if (track.id === id) {
					exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeTrack', [
						this.pcId,
						sender._id
					]);
					delete this.tracks[track.id];
				}
			}
		}
	}
};

RTCPeerConnection.prototype.getOrCreateTrack = function (trackInput) {
	var { id } = trackInput,
		existingTrack = this.tracks[id];

	if (existingTrack) {
		return existingTrack;
	}

	var track;
	if (trackInput instanceof MediaStreamTrack) {
		track = trackInput;
	} else {
		track = new MediaStreamTrack(trackInput);
	}

	this.tracks[id] = track;
	track.addEventListener('ended', () => {
		delete this.tracks[id];
	});

	return track;
};

RTCPeerConnection.prototype.addTransceiver = function (trackOrKind, init) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	var kind,
		track = null,
		self = this,
		trackIdOrKind;
	if (trackOrKind instanceof MediaStreamTrack) {
		kind = trackOrKind.kind;
		track = trackOrKind;
		trackIdOrKind = trackOrKind.id;
	} else {
		if (!(trackOrKind === 'audio' || trackOrKind === 'video')) {
			throw new TypeError(
				'An invalid string was specified as trackOrKind. The string must be either "audio" or "video".'
			);
		}
		kind = trackOrKind;
		trackIdOrKind = trackOrKind;
	}

	var receiverTrackID = newMediaStreamTrackId();

	var receiver = new RTCRtpReceiver(this, {
		track: new MediaStreamTrack({
			id: receiverTrackID,
			kind,
			enabled: true,
			readyState: 'live',
			trackId: 'unknown'
		})
	});

	var sender = new RTCRtpSender(this, {
		track
	});

	var data = init || {};
	data.sender = sender;
	data.receiver = receiver;

	var transceiver = new RTCRtpTransceiver(this, data);

	this.transceivers.push(transceiver);

	var initJson = {};
	if (init && init.direction) {
		initJson.direction = init.direction;
	} else {
		initJson.direction = 'sendrecv';
	}

	if (init && init.sendEncodings) {
		initJson.sendEncodings = init.sendEncodings;
	}

	if (init && init.streams) {
		initJson.streams = init.streams.map((stream) => stream.id);
	} else {
		initJson.streams = [];
	}

	debug(
		'addTransceiver() [trackIdOrKind:%s, init:%o, initJson: %o]',
		trackIdOrKind,
		init,
		initJson
	);

	addTransceiverToPeerConnection(this, trackIdOrKind, initJson, transceiver)
		.then((update) => {
			self.updateTransceiversState(update.transceivers);
		})
		.catch((error) => {
			debugerror('addTransceiver() | failure: %s', error);
		});

	return transceiver;
};

RTCPeerConnection.prototype.updateTransceiversState = function (transceivers) {
	debug('updateTransceiversState()');
	this.transceivers = transceivers.map((transceiver) => {
		const existingTransceiver = this.transceivers.find(
			(localTransceiver) => localTransceiver._id === transceiver.id
		);

		if (existingTransceiver) {
			existingTransceiver.update(transceiver);
			return existingTransceiver;
		}

		return new RTCRtpTransceiver(this, transceiver);
	});
};

RTCPeerConnection.prototype.getStreamById = function (id) {
	debug('getStreamById()');

	return this.localStreams[id] || this.remoteStreams[id] || null;
};

RTCPeerConnection.prototype.addStream = function (stream) {
	var self = this;

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

	stream.addedToConnection = true;

	stream.getTracks().forEach(function (track) {
		self.getOrCreateTrack(track);
	});

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
};

RTCPeerConnection.prototype.removeStream = function (stream) {
	var self = this;

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

	stream.getTracks().forEach(function (track) {
		delete self.tracks[track.id];
	});

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
		throw new Error(
			'getStats() must be called with null or a valid MediaStreamTrack instance as argument'
		);
	}

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	// debug('getStats() [selector:%o]', selector);

	return new Promise(function (resolve, reject) {
		function onResultOK(array) {
			if (isClosed.call(self)) {
				return;
			}

			resolve(new RTCStatsReport(array));
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('getStats() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_getStats', [
			self.pcId,
			selector ? selector.id : null
		]);
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
RTCPeerConnection.prototype_descriptor = Object.getOwnPropertyDescriptors(
	RTCPeerConnection.prototype
);

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
		i,
		len,
		iceServer;

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
		dataChannel,
		transceiver,
		id;

	Object.defineProperty(event, 'target', { value: self, enumerable: true });

	debug('onEvent() | [type:%s, data:%o]', type, data);

	if (data.transceivers) {
		this.updateTransceiversState(data.transceivers);
	}

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
			if (this._localDescription && data.localDescription) {
				this._localDescription.type = data.localDescription.type;
				this._localDescription.sdp = data.localDescription.sdp;
			} else if (data.localDescription) {
				this._localDescription = new RTCSessionDescription(data.localDescription);
			}
			break;

		case 'negotiationneeded':
			break;

		case 'track':
			var track = (event.track = new MediaStreamTrack(data.track));
			event.receiver = new RTCRtpReceiver(self, { track: track });

			transceiver = this.transceivers.find((t) => t.receiver.track.id === track.id);
			event.transceiver = transceiver;
			event.streams = [];

			// Add stream only if available in case of Unified-Plan of track event without stream
			if (data.stream && data.streamId) {
				var stream = this.remoteStreams[data.streamId] || MediaStream.create(data.stream);
				event.streams.push(stream);
			}

			// Store remote track
			this.getOrCreateTrack(track);

			break;

		case 'addstream':
			// Append to the remote streams.
			this.remoteStreams[data.streamId] =
				this.remoteStreams[data.streamId] || MediaStream.create(data.stream);

			event.stream = this.remoteStreams[data.streamId];

			// Emit "connected" on the stream if ICE connected.
			if (
				this.iceConnectionState === 'connected' ||
				this.iceConnectionState === 'completed'
			) {
				event.stream.emitConnected();
			}
			break;

		case 'removestream':
			event.stream = this.remoteStreams[data.streamId];

			// Remove from the remote streams.
			delete this.remoteStreams[data.streamId];
			break;

		case 'datachannel':
			dataChannel = new RTCDataChannel(this, null, null, data.channel);
			event.channel = dataChannel;
			break;
	}

	this.dispatchEvent(event);
}
