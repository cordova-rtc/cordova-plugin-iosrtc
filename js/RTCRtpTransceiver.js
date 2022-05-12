const RTCRtpSender = require('./RTCRtpSender');
const RTCRtpReceiver = require('./RTCRtpReceiver');

/**
 * Expose the RTCRtpTransceiver class.
 */
module.exports = { RTCRtpTransceiver, addTransceiverToPeerConnection };

/**
 * Dependencies.
 */
var debugerror = require('debug')('iosrtc:ERROR:RTCRtpTransceiver'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true }),
	EventTarget = require('./EventTarget');

debugerror.log = console.warn.bind(console);

function addTransceiverToPeerConnection(peerConnection, trackIdOrKind, init, transceiver) {
	return new Promise((resolve, reject) => {
		exec(onResultOK, reject, 'iosrtcPlugin', 'RTCPeerConnection_addTransceiver', [
			peerConnection.pcId,
			trackIdOrKind,
			init,
			transceiver._id,
			transceiver.sender ? transceiver.sender._id : 0,
			transceiver.receiver ? transceiver.receiver._id : 0,
			transceiver.receiver && transceiver.receiver.track
				? transceiver.receiver.track.id
				: null
		]);

		function onResultOK(data) {
			resolve(data);
		}
	});
}

function RTCRtpTransceiver(peerConnection, data) {
	data = data || {};

	this.peerConnection = peerConnection;

	this._id = data.id || randomNumber();
	this._receiver =
		data.receiver instanceof RTCRtpReceiver
			? data.receiver
			: new RTCRtpReceiver(peerConnection, data.receiver);
	this._sender =
		data.sender instanceof RTCRtpSender
			? data.sender
			: new RTCRtpSender(peerConnection, data.sender);
	this._stopped = false;

	if (data.mid) {
		this._mid = data.mid;
	} else {
		this._mid = null;
	}

	if (data.direction) {
		this._direction = data.direction;
		this._currentDirection = data.direction;
	} else {
		this._direction = 'sendrecv';
		this._currentDirection = 'sendrecv';
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
			var self = this;
			this._direction = direction;

			exec(
				onResultOK,
				null,
				'iosrtcPlugin',
				'RTCPeerConnection_RTCRtpTransceiver_setDirection',
				[this.peerConnection.pcId, this._id, direction]
			);

			function onResultOK(data) {
				self.peerConnection.updateTransceiversState(data.transceivers);
			}
		}
	},
	mid: {
		get: function () {
			return this._mid;
		}
	},
	receiver: {
		get: function () {
			return this._receiver;
		}
	},
	sender: {
		get: function () {
			return this._sender;
		}
	},
	stopped: {
		get: function () {
			return this._stopped;
		}
	},
	receiverId: {
		get: function () {
			return this._receiver.track.id;
		}
	}
});

RTCRtpTransceiver.prototype.stop = function () {
	var self = this;

	exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCRtpTransceiver_stop', [
		this.peerConnection.pcId,
		this._id
	]);

	function onResultOK(data) {
		self.peerConnection.updateTransceiversState(data.transceivers);
	}
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
