/**
 * Expose the RTCRtpReceiver class.
 */
export class RTCRtpReceiver {
	private _pc: RTCPeerConnection;
	public track: MediaStreamTrack;

	constructor(data: { pc: RTCPeerConnection; track: MediaStreamTrack }) {
		this._pc = data.pc;
		this.track = data.track;
	}
}
