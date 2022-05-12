/**
 * Expose the MediaStreamTrack class.
 */
module.exports.MediaStreamTrack = MediaStreamTrack;
module.exports.newMediaStreamTrackId = newMediaStreamTrackId;

/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastreamtrack
 */

/**
 * Dependencies.
 */
var debug = require('debug')('iosrtc:MediaStreamTrack'),
	exec = require('cordova/exec'),
	enumerateDevices = require('./enumerateDevices'),
	MediaTrackCapabilities = require('./MediaTrackCapabilities'),
	MediaTrackSettings = require('./MediaTrackSettings'),
	EventTarget = require('./EventTarget');

// Save original MediaStreamTrack
var originalMediaStreamTrack = window.MediaStreamTrack || function dummyMediaStreamTrack() {};

function newMediaStreamTrackId() {
	return window.crypto.getRandomValues(new Uint32Array(4)).join('-');
}

function MediaStreamTrack(dataFromEvent) {
	if (!dataFromEvent) {
		throw new Error('Illegal constructor');
	}

	debug('new() | [dataFromEvent:%o]', dataFromEvent);

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Public atributes.
	this.id = dataFromEvent.id; // NOTE: It's a string.
	this.kind = dataFromEvent.kind;
	this.label = dataFromEvent.label;
	this.muted = false; // TODO: No "muted" property in ObjC API.
	this.capabilities = dataFromEvent.capabilities;
	this.readyState = dataFromEvent.readyState;

	// Private attributes.
	this._enabled = dataFromEvent.enabled;
	this._ended = false;

	this.dataFromEvent = dataFromEvent;

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'MediaStreamTrack_setListener', [this.id]);
}

MediaStreamTrack.prototype = Object.create(EventTarget.prototype);
MediaStreamTrack.prototype.constructor = MediaStreamTrack;

// Static reference to original MediaStreamTrack
MediaStreamTrack.originalMediaStreamTrack = originalMediaStreamTrack;

// Setters.
Object.defineProperty(MediaStreamTrack.prototype, 'enabled', {
	get: function () {
		return this._enabled;
	},
	set: function (value) {
		debug('enabled = %s', !!value);

		this._enabled = !!value;
		exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_setEnabled', [this.id, this._enabled]);
	}
});

MediaStreamTrack.prototype.getConstraints = function () {
	debug('MediaStreamTrack.prototype.getConstraints  is not implemented.');
	return {};
};

MediaStreamTrack.prototype.applyConstraints = function (constraints) {
	debug('MediaStreamTrack.prototype.applyConstraints  is not implemented.', constraints);
	return Promise.reject(new Error('applyConstraints is not implemented.'));
};

MediaStreamTrack.prototype.clone = function () {
	var newTrackId = newMediaStreamTrackId();

	exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_clone', [this.id, newTrackId]);

	return new MediaStreamTrack({
		id: newTrackId,
		kind: this.kind,
		label: this.label,
		readyState: this.readyState,
		enabled: this.enabled,
		trackId: this.dataFromEvent.trackId
	});
};

MediaStreamTrack.prototype.getCapabilities = function () {
	return new MediaTrackCapabilities(this.capabilities);
};

MediaStreamTrack.prototype.getSettings = function () {
	//throw new Error('Not implemented.');
	// SHAM
	return new MediaTrackSettings();
};

MediaStreamTrack.prototype.stop = function () {
	debug('stop()');

	if (this._ended) {
		return;
	}

	exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_stop', [this.id]);
};

// TODO: API methods and events.

/**
 * Class methods.
 */

MediaStreamTrack.getSources = function () {
	debug('getSources()');

	return enumerateDevices.apply(this, arguments);
};

/**
 * Private API.
 */

function onEvent(data) {
	var type = data.type;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'statechange':
			this.readyState = data.readyState;
			this._enabled = data.enabled;

			switch (data.readyState) {
				case 'initializing':
					break;
				case 'live':
					break;
				case 'ended':
					this._ended = true;
					this.dispatchEvent(new Event('ended'));
					break;
				case 'failed':
					break;
			}
			break;
	}
}
