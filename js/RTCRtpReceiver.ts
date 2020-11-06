import { MediaStreamTrackShim } from './MediaStreamTrack';
import { RTCPeerConnectionShim } from './RTCPeerConnection';

export class RTCRtpReceiverShim implements RTCRtpReceiver {
	private _pc: RTCPeerConnectionShim;
	public track: MediaStreamTrackShim;

	constructor(data: { pc: RTCPeerConnectionShim; track: MediaStreamTrackShim }) {
		this._pc = data.pc;
		this.track = data.track;
	}

	/**
	 * Additional, unimplemented members
	 */
	readonly rtcpTransport = null;
	readonly transport = null;

	getContributingSources(): RTCRtpContributingSource[] {
		return [];
	}

	getParameters(): RTCRtpReceiveParameters {
		throw new Error('RTCRtpReceiver.getParameters not implemented');
	}

	getStats(): Promise<RTCStatsReport> {
		throw new Error('RTCRtpReceiver.getStats not implemented');
	}

	getSynchronizationSources(): RTCRtpSynchronizationSource[] {
		return [];
	}
}
