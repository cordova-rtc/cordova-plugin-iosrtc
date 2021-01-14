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

	// Make this an EventTarget.
	EventTarget.call(this);

	this.peerConnection = peerConnection;

	// Created using RTCPeerConnection.addTransceiver
	if (!data) {
		this._currentDirection = "inactive";
		this._direction = "inactive";
		this._mid = null;
		this._receiver = null;
		this._sender = null;
		this.tcId = randomNumber();

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_addTransceiver', [this.peerConnection.pcId, this.tcId, trackOrKind.id, init]);

	// Created by event coming from native.
	} else if(data.tcId) {
		this.tcId = data.tcId;
		this._mid = data.mid;
		this._currentDirection = data.currentDirection;
		this._direction = data.direction;

		this._receiver = data.receiver;
		this._sender = data.sender;

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_setListener', [this.peerConnection.pcId, this.tcId]);

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

			exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_setDirection', [this.peerConnection.pcId, this.tcId, direction]);
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
	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_stop', [this.peerConnection.pcId, this.tcId]);
};

function onEvent(data) {
	var type = data.type;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	if (type !== 'state') {
		return;
	}

	var transceiver = data.transceiver;

	if (transceiver) {
		if (transceiver.direction) {
			this._direction = transceiver.direction;
		}
		if (transceiver.currentDirection) {
			this._currentDirection = transceiver.currentDirection;
		}
		if (transceiver.mid) {
			this._mid = transceiver.mid;
		}
	}
}

// TODO
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/currentDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiverDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/mid
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/stop
