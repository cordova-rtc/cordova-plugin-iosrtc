const RTCRtpSender = require('./RTCRtpSender');
const RTCRtpReceiver = require('./RTCRtpReceiver');

/**
 * Expose the RTCRtpTransceiver class.
 */
module.exports = RTCRtpTransceiver;

/**
 * Dependencies.
 */
var
	debugerror = require('debug')('iosrtc:ERROR:RTCRtpTransceiver'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget');

debugerror.log = console.warn.bind(console);

function RTCRtpTransceiver(peerConnection, trackOrKind, init, initialState, receiverTrackId) {
	initialState = initialState || {};

	this.peerConnection = peerConnection;
	this._receiver = initialState.receiver instanceof RTCRtpReceiver ? initialState.receiver : new RTCRtpReceiver(peerConnection, initialState.receiver);
	this._sender = initialState.sender instanceof RTCRtpSender ? initialState.sender : new RTCRtpSender(peerConnection, initialState.sender);
	this._mid = initialState.mid;
	this._stopped = false;

	if (initialState.tcId) {
		this.tcId = initialState.tcId;
		this._currentDirection = initialState.currentDirection;
		this._direction = initialState.direction;
	} else {
		var mediaStreamTrackIdOrKind;
		if (trackOrKind.id) {
			mediaStreamTrackIdOrKind = trackOrKind.id;
		} else {
			mediaStreamTrackIdOrKind = trackOrKind;
		}

		this._currentDirection = "inactive";

		if (init && init.direction) {
			this._direction = init.direction;
		} else {
			this._direction = "sendrecv";
		}

		this.tcId = randomNumber();

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_addTransceiver', 
			[this.peerConnection.pcId, this.tcId, mediaStreamTrackIdOrKind, init, receiverTrackId]);
	}

	function onResultOK(data) {
		peerConnection.updateTransceiversState(data);
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
	stopped: {
		get: function() {
			return this._stopped;
		}
	}
});

RTCRtpTransceiver.prototype.stop = function () {
	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_stop', [this.peerConnection.pcId, this.tcId]);
};

RTCRtpTransceiver.prototype.update = function (data) {
	if (data.direction) {
		this._direction = data.direction;
	}
	if (data.currentDirection) {
		this._currentDirection = data.currentDirection;
	}
	if (data.mid) {
		this._mid = data.mid;
	}

	this._stopped = data.stopped;

	this.receiver.update(data.receiver);
	this.sender.update(data.sender);
};
