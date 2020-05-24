/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;


function RTCRtpSender(data) {
	data = data || {};

	this.track = data.track;
}