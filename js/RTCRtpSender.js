/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;

function RTCRtpSender(pc ,data) {
	data = data || {};

	this._pc = pc;
	this.track = data.track ? pc.getOrCreateTrack(data.track) : null;
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
		pc = self._pc;

	return new Promise(function (resolve, reject) {
		pc.removeTrack(self);

		if (withTrack) {
			pc.addTrack(withTrack);
		}

		// https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/negotiationneeded_event
		var event = new Event('negotiationneeded');
		pc.dispatchEvent(event);

		pc.addEventListener('signalingstatechange', function listener() {
			if (pc.signalingState === 'closed') {
				pc.removeEventListener('signalingstatechange', listener);
				reject();
			} else if (pc.signalingState === 'stable') {
				pc.removeEventListener('signalingstatechange', listener);
				resolve();
			}
		});
	});
};

RTCRtpSender.prototype.update = function ({ track }) {
	if (track) {
		this.track = this._pc.getOrCreateTrack(track);
	} else {
		this.track = null;
	}
};
