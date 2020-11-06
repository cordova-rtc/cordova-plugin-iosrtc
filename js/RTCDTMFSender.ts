import debugBase from 'debug';
import { EventTargetShim } from './EventTarget';
import { MediaStreamTrackShim } from './MediaStreamTrack';
import { RTCPeerConnectionShim } from './RTCPeerConnection';
import { randomNumber } from './randomNumber';

const debug = debugBase('iosrtc:RTCDTMFSender'),
	exec = require('cordova/exec'),
	defaultDuration = 100,
	defaultInterToneGap = 70;

interface ToneChangeEvent {
	type: 'tonechange';
	tone: string;
}

export class RTCDTMFSenderShim extends EventTargetShim implements RTCDTMFSender {
	// TODO: read these from the properties exposed in Swift?
	private _duration = defaultDuration;
	private _interToneGap = defaultInterToneGap;
	private _toneBuffer = '';
	private dsId = randomNumber();

	constructor(
		private peerConnection: RTCPeerConnectionShim,
		public readonly track: MediaStreamTrackShim
	) {
		super();
		debug('new() | [track:%o]', track);

		const onResultOK = (data: ToneChangeEvent) => this.onEvent(data);
		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDTMFSender', [
			this.peerConnection.pcId,
			this.dsId,
			this._track.id
		]);
	}

	get canInsertDTMF() {
		// TODO: check if it's muted or stopped?
		return this._track && this._track.kind === 'audio' && this._track.enabled;
	}

	get duration() {
		return this._duration;
	}

	get interToneGap() {
		return this._interToneGap;
	}

	get toneBuffer() {
		return this._toneBuffer;
	}

	insertDTMF(tones: string, duration?: number, interToneGap?: number) {
		if (this.isClosed()) {
			return;
		}

		debug(
			'insertDTMF() | [tones:%o, duration:%o, interToneGap:%o]',
			tones,
			duration,
			interToneGap
		);

		if (!tones) {
			return;
		}

		this._duration = duration || defaultDuration;
		this._interToneGap = interToneGap || defaultInterToneGap;

		const onResultOK = (data: any) => this.onEvent(data);
		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDTMFSender_insertDTMF', [
			this.peerConnection.pcId,
			this.dsId,
			tones,
			this._duration,
			this._interToneGap
		]);
	}

	isClosed() {
		return this.peerConnection.signalingState === 'closed';
	}

	onEvent(data: ToneChangeEvent) {
		const type = data.type;

		debug('onEvent() | [type:%s, data:%o]', type, data);

		if (type === 'tonechange') {
			const event = new Event('tonechange');
			(event as any).tone = data.tone;
			this.dispatchEvent(event);
		}
	}

	/**
	 * Additional, unimplemented members
	 */
	ontonechange = null;
}
