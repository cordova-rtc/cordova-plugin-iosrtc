/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;

/**
 * Dependencies.
 */
var MediaStreamTrack = require('./MediaStreamTrack'),
	randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true });

function RTCRtpSender(pc, data) {
	data = data || {};
	this._id = data.id || randomNumber();

	this._pc = pc;
	this.track = data.track || null;
	this.params = data.params || {};
}

RTCRtpSender.prototype.getParameters = function () {
	return this.params;
};

RTCRtpSender.prototype.getStats = function () {
	return this._pc.getStats(this.track);
};

RTCRtpSender.prototype.setParameters = function (params) {
	Object.assign(this.params, params);
	return Promise.resolve(this.params);
};

RTCRtpSender.prototype.replaceTrack = function (withTrack) {
	var self = this,
		pc = self._pc;

	return new Promise((resolve, reject) => {
		pc.removeTrack(self);
		pc.addTrack(withTrack);
		self.track = withTrack;

		// https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/negotiationneeded_event
		var event = new Event('negotiationneeded');
		pc.dispatchEvent(event);

		pc.addEventListener('signalingstatechange', function listener() {
			if (pc.signalingState === 'closed') {
				pc.removeEventListener('signalingstatechange', listener);
				reject();
			} else if (pc.signalingState === 'stable') {
				pc.removeEventListener('signalingstatechange', listener);
				resolve();
			}
		});
	});
};

RTCRtpSender.prototype.update = function ({ track, params }) {
	var self = this;

	if (!(track instanceof MediaStreamTrack) && track !== null) {
		throw new Error(
			'update() must be called with null or a valid MediaStreamTrack instance as argument'
		);
	}

	if (track) {
		this.replaceTrack(track);
	} else {
		self.track = null;
	}

	self.params = params;
};
