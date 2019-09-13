/**
 * Expose the RTCDataChannel class.
 */
module.exports = RTCDataChannel;


/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:RTCDataChannel'),
	debugerror = require('debug')('iosrtc:ERROR:RTCDataChannel'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget');


debugerror.log = console.warn.bind(console);


function RTCDataChannel(peerConnection, label, options, dataFromEvent) {
	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Created via pc.createDataChannel().
	if (!dataFromEvent) {
		debug('new() | [label:%o, options:%o]', label, options);

		if (typeof label !== 'string') {
			label = '';
		}

		options = options || {};

		if (options.hasOwnProperty('maxPacketLifeTime') && options.hasOwnProperty('maxRetransmits')) {
			throw new SyntaxError('both maxPacketLifeTime and maxRetransmits can not be present');
		}

		if (options.hasOwnProperty('id')) {
			if (typeof options.id !== 'number' || isNaN(options.id) || options.id < 0) {
				throw new SyntaxError('id must be a number');
			}
			// TODO:
			//   https://code.google.com/p/webrtc/issues/detail?id=4618
			if (options.id > 1023) {
				throw new SyntaxError('id cannot be greater than 1023 (https://code.google.com/p/webrtc/issues/detail?id=4614)');
			}
		}

		// Public atributes.
		this.label = label;
		this.ordered = options.hasOwnProperty('ordered') ? !!options.ordered : true;
		this.maxPacketLifeTime = options.hasOwnProperty('maxPacketLifeTime') ? Number(options.maxPacketLifeTime) : null;
		this.maxRetransmits = options.hasOwnProperty('maxRetransmits') ? Number(options.maxRetransmits) : null;
		this.protocol = options.hasOwnProperty('protocol') ? String(options.protocol) : '';
		this.negotiated = options.hasOwnProperty('negotiated') ? !!options.negotiated : false;
		this.id = options.hasOwnProperty('id') ? Number(options.id) : undefined;
		this.readyState = 'connecting';
		this.bufferedAmount = 0;
		this.bufferedAmountLowThreshold = 0;

		// Private attributes.
		this.peerConnection = peerConnection;
		this.dcId = randomNumber();

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDataChannel', [this.peerConnection.pcId, this.dcId, label, options]);
	// Created via pc.ondatachannel.
	} else {
		debug('new() | [dataFromEvent:%o]', dataFromEvent);

		// Public atributes.
		this.label = dataFromEvent.label;
		this.ordered = dataFromEvent.ordered;
		this.maxPacketLifeTime = dataFromEvent.maxPacketLifeTime;
		this.maxRetransmits = dataFromEvent.maxRetransmits;
		this.protocol = dataFromEvent.protocol;
		this.negotiated = dataFromEvent.negotiated;
		this.id = dataFromEvent.id;
		this.readyState = dataFromEvent.readyState;
		this.bufferedAmount = dataFromEvent.bufferedAmount;
		this.bufferedAmountLowThreshold = dataFromEvent.bufferedAmountLowThreshold;

		// Private attributes.
		this.peerConnection = peerConnection;
		this.dcId = dataFromEvent.dcId;

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_setListener', [this.peerConnection.pcId, this.dcId]);
	}

	function onResultOK(data) {
		if (data.type) {
			onEvent.call(self, data);
		// Special handler for received binary mesage.
		} else {
			onEvent.call(self, {
				type: 'message',
				message: data
			});
		}
	}
}

RTCDataChannel.prototype = Object.create(EventTarget.prototype);
RTCDataChannel.prototype.constructor = RTCDataChannel;

// Just 'arraybuffer' binaryType is implemented in Chromium.
Object.defineProperty(RTCDataChannel.prototype, 'binaryType', {
	get: function () {
		return 'arraybuffer';
	},
	set: function (type) {
		if (type !== 'arraybuffer') {
			throw new Error('just "arraybuffer" is implemented for binaryType');
		}
	}
});


RTCDataChannel.prototype.send = function (data) {
	if (isClosed.call(this) || this.readyState !== 'open') {
		return;
	}

	debug('send() | [data:%o]', data);

	if (!data) {
		return;
	}

	if (typeof data === 'string' || data instanceof String) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendString', [this.peerConnection.pcId, this.dcId, data]);
	} else if (window.ArrayBuffer && data instanceof window.ArrayBuffer) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [this.peerConnection.pcId, this.dcId, data]);
	} else if (
		(window.Int8Array && data instanceof window.Int8Array) ||
		(window.Uint8Array && data instanceof window.Uint8Array) ||
		(window.Uint8ClampedArray && data instanceof window.Uint8ClampedArray) ||
		(window.Int16Array && data instanceof window.Int16Array) ||
		(window.Uint16Array && data instanceof window.Uint16Array) ||
		(window.Int32Array && data instanceof window.Int32Array) ||
		(window.Uint32Array && data instanceof window.Uint32Array) ||
		(window.Float32Array && data instanceof window.Float32Array) ||
		(window.Float64Array && data instanceof window.Float64Array) ||
		(window.DataView && data instanceof window.DataView)
	) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [this.peerConnection.pcId, this.dcId, data.buffer]);
	} else {
		throw new Error('invalid data type');
	}
};


RTCDataChannel.prototype.close = function () {
	if (isClosed.call(this)) {
		return;
	}

	debug('close()');

	this.readyState = 'closing';

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_close', [this.peerConnection.pcId, this.dcId]);
};


/**
 * Private API.
 */


function isClosed() {
	return this.readyState === 'closed' || this.readyState === 'closing' || this.peerConnection.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		event;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'new':
			// Update properties and exit without firing the event.
			this.ordered = data.channel.ordered;
			this.maxPacketLifeTime = data.channel.maxPacketLifeTime;
			this.maxRetransmits = data.channel.maxRetransmits;
			this.protocol = data.channel.protocol;
			this.negotiated = data.channel.negotiated;
			this.id = data.channel.id;
			this.readyState = data.channel.readyState;
			this.bufferedAmount = data.channel.bufferedAmount;
			break;

		case 'statechange':
			this.readyState = data.readyState;

			switch (data.readyState) {
				case 'connecting':
					break;
				case 'open':
					this.dispatchEvent(new Event('open'));
					break;
				case 'closing':
					break;
				case 'closed':
					this.dispatchEvent(new Event('close'));
					break;
			}
			break;

		case 'message':
			event = new Event('message');
			event.data = data.message;
			this.dispatchEvent(event);
			break;

		case 'bufferedamount':
			this.bufferedAmount = data.bufferedAmount;

			if (this.bufferedAmountLowThreshold > 0 && this.bufferedAmountLowThreshold > this.bufferedAmount) {
				event = new Event('bufferedamountlow');
				event.bufferedAmount = this.bufferedAmount;
				this.dispatchEvent(event);
			}

			break;
	}
}
