/**
 * Expose the RTCRtpSender class.
 */
export class RTCRtpSender {
	private _pc: RTCPeerConnection;
	public track: MediaStreamTrack | null;
	public params: Partial<RTCRtpSendParameters>;

	constructor(data: {
		pc: RTCPeerConnection;
		track: MediaStreamTrack;
		params?: RTCRtpSendParameters;
	}) {
		this._pc = data.pc;
		this.track = data.track;
		this.params = data.params || {};
	}

	getParameters() {
		return this.params;
	}

	setParameters(params: RTCRtpSendParameters) {
		Object.assign(this.params, params);
		return Promise.resolve(this.params);
	}

	replaceTrack(withTrack: MediaStreamTrack | null) {
		const pc = this._pc;

		return new Promise((resolve, reject) => {
			pc.removeTrack(this as any);
			if (withTrack) {
				pc.addTrack(withTrack);
			}
			this.track = withTrack;

			// https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/negotiationneeded_event
			pc.dispatchEvent(new Event('negotiationneeded'));

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
	}
}
