/**
 * Expose the RTCRtpReceiver class.
 */
module.exports = RTCRtpReceiver;


function RTCRtpReceiver(data) {
	data = data || {};

	this.track = data.track;
}
