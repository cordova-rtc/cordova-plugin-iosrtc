/**
 * Expose the RTCRtpReceiver class.
 */
module.exports = RTCRtpReceiver;

function RTCRtpReceiver(pc, data) {
	data = data || {};

	this._pc = pc;
	this.track = pc.getOrCreateTrack(data.track);
}

RTCRtpReceiver.prototype.update = function ({ track }) {
	if (track) {
		this.track = this._pc.getOrCreateTrack(track);
	} else {
		this.track = null;
	}
};
