/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;

function RTCRtpSender(data) {
	data = data || {};

	this.track = data.track;
    this.params = data.params || {};
}

RTCRtpSender.prototype.getParameters = function () {
    return this.params;
};

RTCRtpSender.prototype.setParameters = function (params) {
    Object.assign(this.params, params);
    return Promise.resolve(this.params);
};