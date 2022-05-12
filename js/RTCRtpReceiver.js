/**
 * Expose the RTCRtpReceiver class.
 */
module.exports = RTCRtpReceiver;

var randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true });

function RTCRtpReceiver(pc, data) {
	data = data || {};
	this._id = data.id || randomNumber();

	this._pc = pc;
	this.track = data.track ? pc.getOrCreateTrack(data.track) : null;
	this.params = data.params || {};
}

RTCRtpReceiver.prototype.getParameters = function () {
	return this.params;
};

RTCRtpReceiver.prototype.getStats = function () {
	return this._pc.getStats();
};

RTCRtpReceiver.prototype.update = function ({ track, params }) {
	if (track) {
		this.track = this._pc.getOrCreateTrack(track);
	} else {
		this.track = null;
	}

	this.params = params;
};
