/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastreamtrack
 */

import debugBase from 'debug';
import { enumerateDevices } from './enumerateDevices';
import { MediaTrackCapabilitiesShim } from './MediaTrackCapabilities';
import { MediaTrackSettingsShim } from './MediaTrackSettings';
import { EventTargetShim } from './EventTarget';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:MediaStreamTrack');

// Save original MediaStreamTrack
export const originalMediaStreamTrack =
	window.MediaStreamTrack || function dummyMediaStreamTrack() {};

function newMediaStreamTrackId() {
	return window.crypto.getRandomValues(new Uint32Array(4)).join('-');
}

export type MediaStreamTrackAsJSON = {
	trackId: string;
} & Pick<MediaStreamTrack, 'id' | 'kind' | 'readyState' | 'enabled'>;
type StateChangeEvent = { type: 'statechange' } & Pick<MediaStreamTrack, 'readyState' | 'enabled'>;

export class MediaStreamTrackShim extends EventTargetShim implements MediaStreamTrack {
	id = this.dataFromEvent.id; // NOTE: It's a string.
	kind = this.dataFromEvent.kind;
	label = ''; // Not supplied by swift
	muted = false; // TODO: No "muted" property in ObjC API.
	readyState = this.dataFromEvent.readyState;

	private _enabled = this.dataFromEvent.enabled;
	private _ended = false;

	constructor(private dataFromEvent: MediaStreamTrackAsJSON) {
		super();

		if (!dataFromEvent) {
			throw new Error('Illegal MediaStreamTrack constructor');
		}

		debug('new() | [dataFromEvent:%o]', dataFromEvent);

		const onResultOK = (data: StateChangeEvent) => this.onEvent(data);
		exec(onResultOK, null, 'iosrtcPlugin', 'MediaStreamTrack_setListener', [this.id]);
	}

	get enabled() {
		return this._enabled;
	}
	set enabled(value) {
		debug('enabled = %s', !!value);

		this._enabled = Boolean(value);
		exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_setEnabled', [this.id, this._enabled]);
	}

	getConstraints(): MediaTrackConstraints {
		throw new Error('Not implemented.');
	}

	applyConstraints(constraints?: MediaTrackConstraints) {
		void constraints;
		return Promise.reject('Not implemented.');
	}

	clone() {
		const newTrackId = newMediaStreamTrackId();

		exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_clone', [this.id, newTrackId]);

		return new MediaStreamTrackShim({
			id: newTrackId,
			kind: this.kind,
			readyState: this.readyState,
			enabled: this.enabled,
			trackId: this.dataFromEvent.trackId
		});
	}

	getCapabilities() {
		//throw new Error('Not implemented.');
		// SHAM
		return new MediaTrackCapabilitiesShim();
	}

	getSettings() {
		//throw new Error('Not implemented.');
		// SHAM
		return new MediaTrackSettingsShim();
	}

	stop() {
		debug('stop()');

		if (this._ended) {
			return;
		}

		exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_stop', [this.id]);
	}

	static getSources(...args: any) {
		debug('getSources()');

		return enumerateDevices.apply(this, args);
	}

	private onEvent(data: StateChangeEvent) {
		const type = data.type;

		debug('onEvent() | [type:%s, data:%o]', type, data);

		switch (type) {
			case 'statechange':
				this.readyState = data.readyState;
				this._enabled = data.enabled;

				switch (data.readyState) {
					case 'live':
						break;
					case 'ended':
						this._ended = true;
						this.dispatchEvent(new Event('ended'));
						break;
				}
				break;
		}
	}

	/**
	 * Additional, unimplemented members
	 */
	readonly isolated = false;
	onisolationchange = null;

	/**
	 * Additional events listeners
	 */
	onended = null;
	onmute = null;
	onunmute = null;
}
