/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastream
 */

import debugBase from 'debug';
import { EventTargetShim, extendEventTarget } from './EventTarget';
import {
	MediaStreamTrackShim,
	MediaStreamTrackAsJSON,
	originalMediaStreamTrack
} from './MediaStreamTrack';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:MediaStream');

// Dictionary of MediaStreams (provided via getMediaStreams() class method).
// - key: MediaStream blobId.
// - value: MediaStream.
export const mediaStreams: { [blobId: string]: MediaStreamShim } = {};

// TODO longer UUID like native call
// - "4021904575-2849079001-3048689102-1644344044-4021904575-2849079001-3048689102-1644344044"
function newMediaStreamId() {
	return window.crypto.getRandomValues(new Uint32Array(4)).join('-');
}

// Save original MediaStream or Blob as fallback in older iOS versions
export const originalMediaStream =
	(window.MediaStream as { new (): MediaStream } | undefined) || window.Blob;

export interface MediaStreamAsJSON {
	id: string;
	audioTracks: { [id: string]: MediaStreamTrackAsJSON };
	videoTracks: { [id: string]: MediaStreamTrackAsJSON };
}

interface AddTrackEvent {
	type: 'addtrack';
	track: MediaStreamTrackAsJSON;
}

interface RemoveTrackEvent {
	type: 'removetrack';
	track: MediaStreamTrackAsJSON;
}

type MediaStreamEvent = AddTrackEvent | RemoveTrackEvent;

export const MediaStreamNativeShim = (function (
	this: MediaStreamShim,
	arg?: Blob | MediaStream | MediaStreamTrackShim[],
	id?: string
): MediaStreamShim {
	debug('new MediaStream(arg) | [arg:%o]', arg);

	// Detect native MediaStream usage
	// new MediaStream(originalMediaStream) // stream
	// new MediaStream(originalMediaStreamTrack[]) // tracks
	if (
		(!(arg instanceof window.Blob) &&
			arg instanceof originalMediaStream &&
			!('getBlobId' in arg)) ||
		(Array.isArray(arg) && arg[0] instanceof originalMediaStreamTrack)
	) {
		return new originalMediaStream(arg as any) as MediaStreamShim;
	}

	// new MediaStream(MediaStream) // stream
	// new MediaStream(MediaStreamTrack[]) // tracks
	// new MediaStream() // empty

	id = id || newMediaStreamId();
	const blobId = 'MediaStream_' + id;

	// Extend returned MediaTream with custom MediaStream
	let stream: MediaStreamShim;
	if (originalMediaStream !== window.Blob) {
		// Using native MediaStream class
		stream = new (Function.prototype.bind.apply(originalMediaStream.bind(this), [[]]))();
	} else {
		// Fallback on Blob if originalMediaStream is not a MediaStream and Emulate EventTarget
		stream = (new Blob([blobId], {
			type: 'stream'
		}) as any) as MediaStreamShim;

		const target = document.createTextNode('');
		stream.addEventListener = target.addEventListener.bind(target);
		stream.removeEventListener = target.removeEventListener.bind(target);
		stream.dispatchEvent = target.dispatchEvent.bind(target);
	}

	// Assign all members from the MediaStreamWrapper prototype to extend functionality of the Blob or MediaStream
	Object.defineProperties(stream, Object.getOwnPropertyDescriptors(MediaStreamShim.prototype));

	// Make it an EventTarget.
	extendEventTarget(stream);

	// Public attributes.
	stream._id = id || newMediaStreamId();
	stream._active = true;

	// Init Stream by Id
	exec(null, null, 'iosrtcPlugin', 'MediaStream_init', [stream.id]);

	// Private attributes.
	stream._audioTracks = {};
	stream._videoTracks = {};

	// Store the stream into the dictionary.
	stream._blobId = blobId;
	mediaStreams[stream._blobId] = stream;

	// Convert arg to array of tracks if possible
	if (arg && 'getTracks' in arg) {
		arg = arg.getTracks() as MediaStreamTrackShim[];
	}

	if (Array.isArray(arg)) {
		arg.forEach((track) => {
			stream.addTrack(track);
		});
	} else if (typeof arg !== 'undefined') {
		throw new TypeError(
			"Failed to construct 'MediaStream': No matching constructor signature."
		);
	}

	const onResultOK = (data: MediaStreamEvent) => this.onEvent(data);
	exec(onResultOK, null, 'iosrtcPlugin', 'MediaStream_setListener', [stream.id]);

	return stream;
} as any) as {
	new (arg?: Blob | MediaStream | MediaStreamTrackShim[], id?: string): MediaStreamShim;
};

export class MediaStreamShim extends EventTargetShim implements MediaStream {
	connected = false;
	_active = false;
	addedToConnection = false;
	_audioTracks: { [id: string]: MediaStreamTrackShim } = {};
	_videoTracks: { [id: string]: MediaStreamTrackShim } = {};
	_id = '';
	_label = '';
	_blobId = '';

	get id() {
		return this._id;
	}

	get active() {
		return this._active;
	}

	get label() {
		return this._label;
	}

	getBlobId() {
		return this._blobId;
	}

	getAudioTracks() {
		debug('getAudioTracks()');
		return Object.values(this._audioTracks);
	}

	getVideoTracks() {
		debug('getVideoTracks()');

		return Object.values(this._videoTracks);
	}

	getTracks() {
		debug('getTracks()');

		return [...this.getAudioTracks(), ...this.getVideoTracks()];
	}

	getTrackById(id: string) {
		debug('getTrackById()');

		return this._audioTracks[id] || this._videoTracks[id] || null;
	}

	addTrack(track: MediaStreamTrackShim) {
		debug('addTrack() [track:%o]', track);

		if (!(track instanceof MediaStreamTrackShim)) {
			throw new Error('argument must be an instance of MediaStreamTrack');
		}

		if (this._audioTracks[track.id] || this._videoTracks[track.id]) {
			return;
		}

		if (track.kind === 'audio') {
			this._audioTracks[track.id] = track;
		} else if (track.kind === 'video') {
			this._videoTracks[track.id] = track;
		} else {
			throw new Error('unknown kind attribute: ' + track.kind);
		}

		this.addListenerForTrackEnded(track);

		exec(null, null, 'iosrtcPlugin', 'MediaStream_addTrack', [this.id, track.id]);

		this.dispatchEvent(new Event('update'));

		this.emitConnected();
	}

	removeTrack(track: MediaStreamTrackShim) {
		debug('removeTrack() [track:%o]', track);

		if (!(track instanceof MediaStreamTrackShim)) {
			throw new Error('argument must be an instance of MediaStreamTrack');
		}

		if (!this._audioTracks[track.id] && !this._videoTracks[track.id]) {
			return;
		}

		if (track.kind === 'audio') {
			delete this._audioTracks[track.id];
		} else if (track.kind === 'video') {
			delete this._videoTracks[track.id];
		} else {
			throw new Error('unknown kind attribute: ' + track.kind);
		}

		exec(null, null, 'iosrtcPlugin', 'MediaStream_removeTrack', [this.id, track.id]);

		this.dispatchEvent(new Event('update'));
		this.checkActive();
	}

	clone() {
		const tracks = this.getTracks().map((track) => track.clone());
		return new MediaStreamNativeShim(tracks);
	}

	// Backwards compatible API.
	stop() {
		debug('stop()');

		this.getTracks().forEach((track) => track.stop());
	}

	emitConnected() {
		debug('emitConnected()');

		if (this.connected) {
			return;
		}
		this.connected = true;

		setTimeout(() => {
			const event = new Event('connected');
			Object.defineProperty(event, 'target', { value: this, enumerable: true });
			this.dispatchEvent(event);
		}, 0);
	}

	addListenerForTrackEnded(track: MediaStreamTrackShim) {
		track.addEventListener('ended', () => {
			if (track.kind === 'audio' && !this._audioTracks[track.id]) {
				return;
			} else if (track.kind === 'video' && !this._videoTracks[track.id]) {
				return;
			}

			this.checkActive();
		});
	}

	private checkActive() {
		// A MediaStream object is said to be active when it has at least one MediaStreamTrack
		// that has not ended. A MediaStream that does not have any tracks or only has tracks
		// that are ended is inactive.

		if (!this.active) {
			return;
		}

		// Fixes Twilio fails to read a local video if the stream is released.
		if (this.addedToConnection) {
			return;
		}

		if (
			Object.keys(this._audioTracks).length === 0 &&
			Object.keys(this._videoTracks).length === 0
		) {
			debug('no tracks, releasing MediaStream');

			this.release();
			return;
		}

		for (const trackId in this._audioTracks) {
			if (this._audioTracks.hasOwnProperty(trackId)) {
				if (this._audioTracks[trackId].readyState !== 'ended') {
					return;
				}
			}
		}

		for (const trackId in this._videoTracks) {
			if (this._videoTracks.hasOwnProperty(trackId)) {
				if (this._videoTracks[trackId].readyState !== 'ended') {
					return;
				}
			}
		}

		debug('all tracks are ended, releasing MediaStream %s', this.id);
		this.release();
	}

	private release() {
		this._active = false;
		this.dispatchEvent(new Event('inactive'));

		// Remove the stream from the dictionary.
		delete mediaStreams[this._blobId];

		exec(null, null, 'iosrtcPlugin', 'MediaStream_release', [this.id]);
	}

	protected onEvent(data: MediaStreamEvent) {
		const type = data.type;
		let track: MediaStreamTrackShim | undefined,
			event: Event & { track?: MediaStreamTrackShim };

		debug('onEvent() | [type:%s, data:%o]', type, data);

		switch (type) {
			case 'addtrack':
				// check if a track already exists before initializing a new
				// track and calling setListener again.
				if (data.track.kind === 'audio') {
					track = this._audioTracks[data.track.id];
				} else if (data.track.kind === 'video') {
					track = this._videoTracks[data.track.id];
				}

				if (!track) {
					track = new MediaStreamTrackShim(data.track);

					if (track.kind === 'audio') {
						this._audioTracks[track.id] = track;
					} else if (track.kind === 'video') {
						this._videoTracks[track.id] = track;
					}
					this.addListenerForTrackEnded(track);
				}

				event = new Event('addtrack');
				event.track = track;

				this.dispatchEvent(event);

				// Also emit 'update' for the MediaStreamRenderer.
				this.dispatchEvent(new Event('update'));
				break;

			case 'removetrack':
				if (data.track.kind === 'audio') {
					track = this._audioTracks[data.track.id];
					delete this._audioTracks[data.track.id];
				} else if (data.track.kind === 'video') {
					track = this._videoTracks[data.track.id];
					delete this._videoTracks[data.track.id];
				}

				if (!track) {
					throw new Error(
						'"removetrack" event fired on MediaStream for a non existing MediaStreamTrack'
					);
				}

				event = new Event('removetrack');
				event.track = track;

				this.dispatchEvent(event);

				// Also emit 'update' for the MediaStreamRenderer.
				this.dispatchEvent(new Event('update'));

				// Check whether the MediaStream still is active.
				this.checkActive();
				break;
		}
	}

	/**
	 * Additional events listeners
	 */
	onaddtrack = null;
	onremovetrack = null;
}

export function createMediaStream(dataFromEvent: MediaStreamAsJSON) {
	debug('create() | [dataFromEvent:%o]', dataFromEvent);

	const stream = new MediaStreamNativeShim([], dataFromEvent.id);

	// We do not use addTrack to prevent false positive "ERROR: video track not added" and "ERROR: audio track not added"
	// cause the rtcMediaStream already has them internally.

	Object.values(dataFromEvent.audioTracks).forEach((trackAsJSON) => {
		const track = new MediaStreamTrackShim(trackAsJSON);

		stream._audioTracks[track.id] = track;
		stream.addListenerForTrackEnded(track);
	});

	Object.values(dataFromEvent.videoTracks).forEach((trackAsJSON) => {
		const track = new MediaStreamTrackShim(trackAsJSON);

		stream._videoTracks[track.id] = track;
		stream.addListenerForTrackEnded(track);
	});

	return stream;
}
