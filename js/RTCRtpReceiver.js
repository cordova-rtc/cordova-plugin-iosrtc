/**
 * Expose the RTCRtpReceiver class.
 */
module.exports = RTCRtpReceiver;

function RTCRtpReceiver(data) {
	data = data || {};

	this._pc = data.pc;
	this.track = data.track;
}
