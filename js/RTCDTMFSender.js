/**
 * Expose the RTCDTMFSender class.
 */
module.exports = RTCDTMFSender;


/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:RTCDTMFSender'),
	debugerror = require('debug')('iosrtc:ERROR:RTCDTMFSender'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget');


debugerror.log = console.warn.bind(console);


function RTCDTMFSender(peerConnection, track) {
	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	debug('new() | [track:%o]', track);

	// Public atributes (accessed as read-only properties)
	this._track = track;
	// TODO: read these from the properties exposed in Swift?
	this._duration = 100;
	this._interToneGap = 70;
	this._toneBuffer = '';

	// Private attributes.
	this.peerConnection = peerConnection;
	this.dsId = randomNumber();

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDTMFSender', [this.peerConnection.pcId, this.dsId, this._track.id]);

}

RTCDTMFSender.prototype = Object.create(EventTarget.prototype);
RTCDTMFSender.prototype.constructor = RTCDTMFSender;

Object.defineProperty(RTCDTMFSender.prototype, 'canInsertDTMF', {
	get: function () {
		// TODO: check if it's muted or stopped?
		return this._track && this._track.kind === 'audio' && this._track.enabled;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'track', {
	get: function () {
		return this._track;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'duration', {
	get: function () {
		return this._duration;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'interToneGap', {
	get: function () {
		return this._interToneGap;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'toneBuffer', {
	get: function () {
		return this._toneBuffer;
	}
});


RTCDTMFSender.prototype.insertDTMF = function (tones, duration, interToneGap) {
	if (isClosed.call(this)) {
		return;
	}

	debug('insertDTMF() | [tones:%o, duration:%o, interToneGap:%o]', tones, duration, interToneGap);

	if (!tones) {
		return;
	}

	this._duration = duration || 100;
	this._interToneGap = interToneGap || 70;

	var self = this;

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDTMFSender_insertDTMF', [this.peerConnection.pcId, this.dsId, tones, this._duration, this._interToneGap]);
};


/**
 * Private API.
 */


function isClosed() {
	return this.peerConnection.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		event;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	if (type === 'tonechange') {
		event = new Event('tonechange');
		event.tone = data.tone;
		this.dispatchEvent(event);
	}
}
