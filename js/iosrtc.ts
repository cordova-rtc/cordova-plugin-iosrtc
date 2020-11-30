import debugBase from 'debug';
import { getUserMedia } from './getUserMedia';
import { enumerateDevices } from './enumerateDevices';
import { RTCPeerConnectionShim } from './RTCPeerConnection';
import { RTCSessionDescriptionShim } from './RTCSessionDescription';
import { RTCIceCandidateShim } from './RTCIceCandidate';
import { MediaDevicesShim } from './MediaDevices';
import { MediaStreamShim, mediaStreams, MediaStreamNativeShim } from './MediaStream';
import { MediaStreamTrackShim } from './MediaStreamTrack';
import {
	initializeVideoElementsHandler,
	observeVideo,
	refreshVideos
} from './videoElementsHandler';
import { MediaStreamRenderer, mediaStreamRenderers } from './MediaStreamRenderer';

const debug = debugBase('iosrtc'),
	exec = require('cordova/exec'),
	domready = require('domready');

/**
 * Expose the iosrtc object.
 */
module.exports = {
	// Expose WebRTC classes and functions.
	getUserMedia: getUserMedia,
	enumerateDevices: enumerateDevices,
	getMediaDevices: enumerateDevices, // TMP
	RTCPeerConnection: RTCPeerConnectionShim,
	RTCSessionDescription: RTCSessionDescriptionShim,
	RTCIceCandidate: RTCIceCandidateShim,
	MediaDevices: MediaDevicesShim,
	MediaStream: MediaStreamShim,
	MediaStreamTrack: MediaStreamTrackShim,

	// Expose a function to refresh current videos rendering a MediaStream.
	refreshVideos: refreshVideos,

	// Expose a function to handle a video not yet inserted in the DOM.
	observeVideo: observeVideo,

	// Select audio output (earpiece or speaker).
	selectAudioOutput: selectAudioOutput,

	// turnOnSpeaker with options
	turnOnSpeaker: turnOnSpeaker,

	// Checking permision (audio and camera)
	requestPermission: requestPermission,

	// Expose a function to initAudioDevices if needed, sets the audio session active
	initAudioDevices: initAudioDevices,

	// Expose a function to pollute window and naigator namespaces.
	registerGlobals: registerGlobals,

	// Expose the debug module.
	debug: require('debug'),

	// Debug function to see what happens internally.
	dump: dump,

	// Debug Stores to see what happens internally.
	mediaStreamRenderers: mediaStreamRenderers,
	mediaStreams: mediaStreams
};

domready(function () {
	initializeVideoElementsHandler();

	// refreshVideos on device orientation change to resize peers video
	// while local video will resize du orientation change
	window.addEventListener('resize', () => refreshVideos());
});

function selectAudioOutput(output: 'earpiece' | 'speaker') {
	debug('selectAudioOutput() | [output:"%s"]', output);

	switch (output) {
		case 'earpiece':
			exec(null, null, 'iosrtcPlugin', 'selectAudioOutputEarpiece', []);
			break;
		case 'speaker':
			exec(null, null, 'iosrtcPlugin', 'selectAudioOutputSpeaker', []);
			break;
		default:
			throw new Error('output must be "earpiece" or "speaker"');
	}
}

function turnOnSpeaker(isTurnOn: boolean) {
	debug('turnOnSpeaker() | [isTurnOn:"%s"]', isTurnOn);

	exec(null, null, 'iosrtcPlugin', 'RTCTurnOnSpeaker', [isTurnOn]);
}

function requestPermission(
	needMic: boolean,
	needCamera: boolean,
	callback: (permissionGranted: boolean) => any
) {
	debug('requestPermission() | [needMic:"%s", needCamera:"%s"]', needMic, needCamera);

	function ok() {
		callback(true);
	}

	function error() {
		callback(false);
	}
	exec(ok, error, 'iosrtcPlugin', 'RTCRequestPermission', [needMic, needCamera]);
}

function initAudioDevices() {
	debug('initAudioDevices()');

	exec(null, null, 'iosrtcPlugin', 'initAudioDevices', []);
}

function callbackifyMethod<T>(originalMethod: (...args: any[]) => Promise<T>) {
	return function (this: any, ...args: any[]): Promise<T> {
		// eslint-disable-next-line @typescript-eslint/ban-types
		let success: Function | null = null,
			// eslint-disable-next-line @typescript-eslint/ban-types
			failure: Function | null = null;

		const callbackArgs: any[] = [];
		args.forEach(function (arg) {
			if (typeof arg === 'function') {
				if (!success) {
					success = arg;
				} else {
					failure = arg;
				}
			} else {
				callbackArgs.push(arg);
			}
		});

		let promiseResult = originalMethod.apply(this, callbackArgs);

		// Only apply then if callback success available
		if (success) {
			promiseResult = promiseResult.then(success);
		}

		// Only apply catch if callback failure available
		if (typeof failure === 'function') {
			promiseResult = promiseResult.catch(failure);
		}

		return promiseResult;
	};
}

function callbackifyPrototype(proto: any, method: string) {
	const originalMethod = proto[method];
	proto[method] = callbackifyMethod(originalMethod);
}

function restoreCallbacksSupport() {
	debug('restoreCallbacksSupport()');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'createAnswer');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'createOffer');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'setRemoteDescription');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'setLocalDescription');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'addIceCandidate');
	callbackifyPrototype(RTCPeerConnectionShim.prototype, 'getStats');
}

function registerGlobals(doNotRestoreCallbacksSupport = false) {
	debug('registerGlobals()');

	if (!global.navigator) {
		(global as any).navigator = {};
	}

	if (!navigator.mediaDevices) {
		(navigator as any).mediaDevices = new MediaDevicesShim();
	}

	// Restore Callback support
	let getUserMediaShim = getUserMedia,
		enumerateDevicesShim = enumerateDevices;
	if (!doNotRestoreCallbacksSupport) {
		restoreCallbacksSupport();
		getUserMediaShim = callbackifyMethod(getUserMedia);
		enumerateDevicesShim = callbackifyMethod(enumerateDevices);
	}

	navigator.getUserMedia = getUserMediaShim;
	(navigator as any).webkitGetUserMedia = getUserMediaShim;
	navigator.mediaDevices.getUserMedia = getUserMediaShim;
	navigator.mediaDevices.enumerateDevices = enumerateDevicesShim;

	(window as any).RTCPeerConnection = RTCPeerConnectionShim;
	window.webkitRTCPeerConnection = RTCPeerConnectionShim;
	(window as any).RTCSessionDescription = RTCSessionDescriptionShim;
	window.RTCIceCandidate = RTCIceCandidateShim;
	(window as any).MediaStream = MediaStreamNativeShim;
	(window as any).webkitMediaStream = MediaStreamNativeShim;
	(window.MediaStreamTrack as any) = MediaStreamTrackShim;

	// Apply CanvasRenderingContext2D.drawImage monkey patch
	const originalDrawImage = CanvasRenderingContext2D.prototype.drawImage;
	CanvasRenderingContext2D.prototype.drawImage = function (
		arg: CanvasImageSource & { render?: MediaStreamRenderer },
		...additionalArgs: number[]
	) {
		if (arg instanceof HTMLVideoElement && arg.render) {
			arg.render.save((data) => {
				const img = new window.Image();
				img.addEventListener('load', () => {
					originalDrawImage.apply(this, [
						img,
						...additionalArgs
					] as CanvasDrawImage['drawImage']['arguments']);
					img.src = '';
				});
				img.setAttribute('src', 'data:image/jpg;base64,' + data);
			});
		} else {
			return originalDrawImage.apply(this, [
				arg,
				...additionalArgs
			] as CanvasDrawImage['drawImage']['arguments']);
		}
	};
}

function dump() {
	exec(null, null, 'iosrtcPlugin', 'dump', []);
}
