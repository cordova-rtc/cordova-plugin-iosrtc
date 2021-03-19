const RTCRtpEncodingParameters = require('./RTCRtpEncodingParameters');

class RTCRtpSendParameters {
	constructor(params) {
		this.encodings = params || new RTCRtpEncodingParameters();
	}
}
/**
 * Expose the RTCRtpSendParameters class.
 */
module.exports = RTCRtpSendParameters;
