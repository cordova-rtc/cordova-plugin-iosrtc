import { RTCRtpReceiverShim } from './RTCRtpReceiver';
import { RTCRtpSenderShim } from './RTCRtpSender';

export class RTCRtpTransceiverShim implements RTCRtpTransceiver {
	public receiver: RTCRtpReceiverShim;
	public sender: RTCRtpSenderShim;
	public direction: RTCRtpTransceiverDirection;

	constructor(data: { receiver?: RTCRtpReceiverShim; sender?: RTCRtpSenderShim } = {}) {
		// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
		this.receiver = data.receiver!;
		// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
		this.sender = data.sender!;

		if (data.receiver && data.sender) {
			this.direction = 'sendrecv' as const;
		} else if (data.receiver) {
			this.direction = 'recvonly';
		} else {
			this.direction = 'sendonly';
		}
	}

	/**
	 * Additional, unimplemented members
	 */
	readonly currentDirection = null;
	readonly mid = null;
	setCodecPreferences(codecs: RTCRtpCodecCapability[]): void {
		void codecs;
		throw new Error('RTCRtpTransceiver.setCodecPreferences not implemented');
	}
	stop(): void {}
}

// TODO
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/currentDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiverDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/mid
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/stop
