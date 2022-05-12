/**
 * Expose the RTCRtpSender class.
 */
module.exports = RTCRtpSender;

/**
 * Dependencies.
 */
var exec = require('cordova/exec'),
	{ MediaStreamTrack } = require('./MediaStreamTrack'),
	randomNumber = require('random-number').generator({ min: 10000, max: 99999, integer: true });

function RTCRtpSender(pc, data) {
	data = data || {};
	this._id = data.id || randomNumber();

	this._pc = pc;
	this.track = data.track ? pc.getOrCreateTrack(data.track) : null;
	this.params = data.params || {};
	if (this.track) {
		this.dtmf = pc.createDTMFSender(this.track);
	}
}

RTCRtpSender.prototype.getParameters = function () {
	return this.params;
};

RTCRtpSender.prototype.getStats = function () {
	return this._pc.getStats();
};

RTCRtpSender.prototype.setParameters = function (params) {
	Object.assign(this.params, params);
	return new Promise((resolve, reject) => {
		function onResultOK(result) {
			resolve(result);
		}

		function onResultError(error) {
			reject(error);
		}

		exec(
			onResultOK,
			onResultError,
			'iosrtcPlugin',
			'RTCPeerConnection_RTCRtpSender_setParameters',
			[this._pc.pcId, this._id, params]
		);
	});
};

RTCRtpSender.prototype.replaceTrack = function (withTrack) {
	var self = this,
		pc = self._pc;

	return new Promise((resolve, reject) => {
		function onResultOK(result) {
			self.track = result.track ? new MediaStreamTrack(result.track) : null;
			resolve();
		}

		function onResultError(error) {
			reject(error);
		}

		var trackId = withTrack ? withTrack.id : null;

		exec(
			onResultOK,
			onResultError,
			'iosrtcPlugin',
			'RTCPeerConnection_RTCRtpSender_replaceTrack',
			[this._pc.pcId, this._id, trackId]
		);

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

RTCRtpSender.prototype.update = function ({ track, params }) {
	if (track) {
		this.track = this._pc.getOrCreateTrack(track);
	} else {
		this.track = null;
	}

	this.params = params;
};
