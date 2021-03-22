class RTCRtpEncodingParameters {
	constructor(data) {
		if (data) {
			Object.assign(this, data);
		}
		this.codecs = this.codecs || [];
		this.encodings = this.encodings || [];
		this.headerExtensions = this.headerExtensions || [];
		this.rtcp = this.rtcp || {};
		this.transactionId = this.transactionId || null;
	}
}
/**
 * Expose the RTCRtpEncodingParameters class.
 */
module.exports = RTCRtpEncodingParameters;
