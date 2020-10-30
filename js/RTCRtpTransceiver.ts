import { RTCRtpReceiver } from './RTCRtpReceiver';
import { RTCRtpSender } from './RTCRtpSender';

/**
 * Expose the RTCRtpTransceiver class.
 */
export class RTCRtpTransceiver {
	public receiver?: RTCRtpReceiver;
	public sender?: RTCRtpSender;

	constructor(data: { receiver?: RTCRtpReceiver; sender?: RTCRtpSender } = {}) {
		this.receiver = data.receiver;
		this.sender = data.sender;
	}
}

// TODO
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/currentDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiverDirection
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/mid
// https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver/stop
