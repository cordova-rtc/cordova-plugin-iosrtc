/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;

function RTCRtpSender(data) {
	data = data || {};

	this._pc = data.pc;
	this._stream = data.stream;
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

RTCRtpSender.prototype.replaceTrack = function (withTrack) {
	var self = this,
		pc = self._pc,
		stream = self._stream,
		track = self.track;

	return new Promise(function (resolve, reject) {
		stream.removeTrack(track);
		stream.addTrack(withTrack);
		self.track = withTrack;

		pc.removeStream(stream);
		pc.addStream(stream);

		// https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/negotiationneeded_event
		var event = new Event('negotiationneeded');
		pc.dispatchEvent('negotiationneeded', event);

		pc.addEventListener("signalingstatechange", function listener() {
			if (pc.signalingState === "closed") {
				pc.removeEventListener("signalingstatechange", listener);
				reject();
			} else if (pc.signalingState === "stable") {
				pc.removeEventListener("signalingstatechange", listener);
				resolve();
			}
		});
	});
};