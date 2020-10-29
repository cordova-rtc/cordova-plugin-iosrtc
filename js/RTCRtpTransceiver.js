/**
 * Expose the RTCRtpTransceiver class.
 */
module.exports = RTCRtpTransceiver;

function RTCRtpTransceiver(data) {
	data = data || {};

	this.receiver = data.receiver;
	this.sender = data.sender;
}

// TODO
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/currentDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiverDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/mid
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/stop
