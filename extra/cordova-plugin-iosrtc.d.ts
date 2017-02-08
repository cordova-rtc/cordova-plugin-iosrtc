// Type definitions for cordova-plugin-iosrtc v3.2.2
// Project: https://github.com/eface2face/cordova-plugin-iosrtc
// Definitions by: Konstantin Mamaev <https://github.com/MrMeison/>

///<reference types="webrtc" />
interface Window {
	plugins: CordovaPlugins;
}

interface CordovaPlugins {
	iosrtc: IOsRtc;
}

interface IOsRtc {
	/**
	 * Implementation of the getUserMedia() function as specified by the W3C Media Capture and Streams draft.
	 * @see https://w3c.github.io/mediacapture-main/#local-content
	 *
	 * @type {NavigatorGetUserMedia}
	 * @memberOf IOsRtc
	 */
	getUserMedia: NavigatorGetUserMedia;

	/**
	 * Implementation of the enumerateDevices() function as specified in the W3C Media Capture and Streams draft.
	 * @see https://w3c.github.io/mediacapture-main/#enumerating-devices
	 *
	 * @returns {Promise<MediaDeviceInfo[]>}
	 *
	 * @memberOf IOsRtc
	 */
	enumerateDevices(): Promise<MediaDeviceInfo[]>;

	/**
	 * Exposes the RTCPeerConnection class as defined by the W3C Real-time Communication Between Browsers draft.
	 * @see https://www.w3.org/TR/webrtc/#rtcpeerconnection-interface
	 *
	 * @type {RTCPeerConnectionStatic}
	 * @memberOf IOsRtc
	 */
	RTCPeerConnection: RTCPeerConnectionStatic;

	/**
	 * Exposes the RTCSessionDescription class as defined by the W3C Real-time Communication Between Browsers draft.
	 * @see https://www.w3.org/TR/webrtc/#idl-def-RTCSessionDescription
	 *
	 * @type {RTCSessionDescriptionStatic}
	 * @memberOf IOsRtc
	 */
	RTCSessionDescription: RTCSessionDescriptionStatic;

	/**
	 * Exposes the RTCSessionDescription class as defined by the W3C Real-time Communication Between Browsers draft.
	 * @see https://www.w3.org/TR/webrtc/#idl-def-RTCIceCandidate
	 *
	 * @type {RTCIceCandidateStatic}
	 * @memberOf IOsRtc
	 */
	RTCIceCandidate: RTCIceCandidateStatic;

	/**
	 * Exposes the MediaStream class as defined by the W3C Real-time Communication Between Browsers draft.
	 * @see https://w3c.github.io/mediacapture-main/#mediastream
	 * NOTES:
	 * For internal reasons the MediaStream class points to the Blob class, so the MediaStream class constructor is not implemented (this class is exposed to make some WebRTC polyfill libraries happy).
	 * stop() method implemented for backwards compatibility (it calls stop() on all its MediaStreamTracks).
	 *
	 * @type {MediaStream}
	 * @memberOf IOsRtc
	 */
	MediaStream: MediaStream;

	/**
	 * Exposes the MediaStreamTrack class as defined by the W3C Real-time Communication Between Browsers draft.
	 * NOTES:
	 * The only reason to make this class public is to expose the deprecated MediaStreamTrack.getSources() class function,
	 * which is an "alias" to the enumerateDevices() function described above.
	 *
	 * @type {MediaStreamTrack}
	 * @memberOf IOsRtc
	 */
	MediaStreamTrack: MediaStreamTrack;

	/**
	 * When calling this method, the height/width, opacity, visibility and z-index of all the HTML5 video elements rendering
	 * a MediaStream are recomputed and the iOS native UIView layer updated according.
	 * NOTE: Call this method when the position or size of a video element changes.
	 *
	 * @memberOf IOsRtc
	 */
	refreshVideos(): void;

	/**
	 * Tell the plugin that it must monitor the given HTML5 video element.
	 * NOTE: This method should just be used for those <video> elements not yet inserted into the DOM in which the app want to attach a MediaStream.
	 * If the video element is already placed into the DOM at the time a MediaStream is attached to it then calling this method is not needed at all.
	 *
	 * @param {HTMLVideoElement} videoElement
	 *
	 * @memberOf IOsRtc
	 */
	observeVideo(videoElement: HTMLVideoElement): void;

	/**
	 * Select the audio output device
	 *
	 * @param {("earpiece" | "speaker")} output
	 *
	 * @memberOf IOsRtc
	 */
	selectAudioOutput(output: "earpiece" | "speaker"): void;

	/**
	 * By calling this method the JavaScript global namespace
	 * Useful to avoid iOS specified code in your HTML5 application.
	 *
	 * @memberOf IOsRtc
	 */
	registerGlobals(): void;

	/**
	 * The debug module. Useful to enable verbose logging
	 * @example cordova.plugins.iosrtc.debug.enable('iosrtc*');
	 *
	 * @type {{
	 * 		enable(enabled: string): void;
	 * 	}}
	 * @memberOf IOsRtc
	 */
	debug: {
		enable(enabled: string): void;
	}

	/**
	 * A plugin interface for rtcninja.
	 * @see https://github.com/eface2face/rtcninja.js/
	 *
	 * @type {*}
	 * @memberOf IOsRtc
	 */
	rtcninjaPlugin: any;

}
