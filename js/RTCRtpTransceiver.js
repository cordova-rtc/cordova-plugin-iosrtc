/**
 * Expose the RTCRtpTransceiver class.
 */
module.exports = RTCRtpTransceiver;

/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:RTCRtpTransceiver'),
	debugerror = require('debug')('iosrtc:ERROR:RTCRtpTransceiver'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget');

debugerror.log = console.warn.bind(console);

function RTCRtpTransceiver(peerConnection, trackOrKind, init, data) {
	var self = this;

	// Created using RTCPeerConnection.addTransceiver
	if (!data) {
		// Make this an EventTarget.
		EventTarget.call(this);

		// Private attributes.
		this.peerConnection = peerConnection;
		this._currentDirection = "sendrecv";
		this._direction = "sendrecv";
		this._mid = null;
		this._receiver = null;
		this._sender = null;
		this.tcId = randomNumber();

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_addTransceiver', [this.peerConnection.pcId, this.tcId, trackOrKind.id, init]);

	// Created using RTCPeerConnection.getTransceivers
	} else {
		this._receiver = data.receiver;
		this._sender = data.sender;
	}

	function onResultOK(data) {
		onEvent.call(self, data);
	}
}

RTCRtpTransceiver.prototype = Object.create(EventTarget.prototype);
RTCRtpTransceiver.prototype.constructor = RTCRtpTransceiver;

Object.defineProperties(RTCRtpTransceiver.prototype, {
	currentDirection: {
		get: function () {
			return this._currentDirection;
		}
	},
	direction: {
		get: function () {
			return this._direction;
		},
		set: function (direction) {
			this._direction = direction;
			// TODO: Invoke native api
		}
	},
	mid: {
		get: function () {
			return this._mid;
		}
	},
	receiver: {
		get: function() {
			return this._receiver;
		}
	},
	sender: {
		get: function() {
			return this._sender;
		}
	},
});

RTCRtpTransceiver.prototype.stop = function () {
	// TODO: Implement stop function

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_close', [this.peerConnection.pcId, this.tcId]);
};

function onEvent(data) {
	var type = data.type;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'direction':
			this._direction = data.direction;
			this._currentDirection = data.direction;

			break;

		case 'mid':
			this._mid = data.mid;

			break;

		case 'receiver':
			this._receiver = data.receiver;

			break;

		case 'sender':
			this._sender = data.sender;

			break;
	}
}

// TODO
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/currentDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiverDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/mid
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/stop
