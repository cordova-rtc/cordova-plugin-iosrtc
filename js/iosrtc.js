/**
 * Variables.
 */

var
	// Dictionary of MediaStreamRenderers.
	// - key: MediaStreamRenderer id.
	// - value: MediaStreamRenderer.
	mediaStreamRenderers = {},

	// Dictionary of MediaStreams.
	// - key: MediaStream blobId.
	// - value: MediaStream.
	mediaStreams = {},


/**
 * Dependencies.
 */
	debug                  = require('debug')('iosrtc'),
	exec                   = require('cordova/exec'),
	domready               = require('domready'),

	getUserMedia           = require('./getUserMedia'),
	enumerateDevices       = require('./enumerateDevices'),
	RTCPeerConnection      = require('./RTCPeerConnection'),
	RTCSessionDescription  = require('./RTCSessionDescription'),
	RTCIceCandidate        = require('./RTCIceCandidate'),
	MediaStream            = require('./MediaStream'),
	MediaStreamTrack       = require('./MediaStreamTrack'),
	videoElementsHandler   = require('./videoElementsHandler');


/**
 * Expose the iosrtc object.
 */
module.exports = {
	// Expose WebRTC classes and functions.
	getUserMedia:          getUserMedia,
	enumerateDevices:      enumerateDevices,
	getMediaDevices:       enumerateDevices,  // TMP
	RTCPeerConnection:     RTCPeerConnection,
	RTCSessionDescription: RTCSessionDescription,
	RTCIceCandidate:       RTCIceCandidate,
	MediaStream:           MediaStream,
	MediaStreamTrack:      MediaStreamTrack,

	// Expose a function to refresh current videos rendering a MediaStream.
	refreshVideos:         refreshVideos,

	// Expose a function to handle a video not yet inserted in the DOM.
	observeVideo:          videoElementsHandler.observeVideo,

	// Expose a function to pollute window and naigator namespaces.
	registerGlobals:       registerGlobals,

	// Expose the debug module.
	debug:                 require('debug'),

	// Debug function to see what happens internally.
	dump:                  dump
};


domready(function () {
	// Let the MediaStream class and the videoElementsHandler share same MediaStreams container.
	MediaStream.setMediaStreams(mediaStreams);
	videoElementsHandler(mediaStreams, mediaStreamRenderers);
});


function refreshVideos() {
	debug('refreshVideos()');

	var id;

	for (id in mediaStreamRenderers) {
		if (mediaStreamRenderers.hasOwnProperty(id)) {
			mediaStreamRenderers[id].refresh();
		}
	}
}

function callbackifyMethod(originalMethod) {
  	return function () {
		var success, failure,
		  originalArgs = Array.prototype.slice.call(arguments);

		var callbackArgs = [];
		originalArgs.forEach(function (arg) {
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

		var promiseResult = originalMethod.apply(this, callbackArgs);

		// Only apply then if callback success available
		if (typeof success === 'function') {
			promiseResult = promiseResult.then(success);
		}

		// Only apply catch if callback failure available
		if (typeof failure === 'function') {
			promiseResult = promiseResult.catch(failure);
		}

		return promiseResult;
	};
}

function callbackifyPrototype(proto, method) {
	var originalMethod = proto[method];
	proto[method] = callbackifyMethod(originalMethod);
}

function restoreCallbacksSupport() {
	debug('restoreCallbacksSupport()');
	getUserMedia = callbackifyMethod(getUserMedia);
	enumerateDevices = callbackifyMethod(enumerateDevices);
	callbackifyPrototype(RTCPeerConnection.prototype, 'createAnswer');
	callbackifyPrototype(RTCPeerConnection.prototype, 'createOffer');
	callbackifyPrototype(RTCPeerConnection.prototype, 'setRemoteDescription');
	callbackifyPrototype(RTCPeerConnection.prototype, 'setLocalDescription');
	callbackifyPrototype(RTCPeerConnection.prototype, 'addIceCandidate');
}

function registerGlobals(doNotRestoreCallbacksSupport) {
	debug('registerGlobals()');

	if (!global.navigator) {
		global.navigator = {};
	}

	if (!navigator.mediaDevices) {
		navigator.mediaDevices = {};
	}

	navigator.getUserMedia                  = getUserMedia;
	navigator.webkitGetUserMedia            = getUserMedia;
	navigator.mediaDevices.getUserMedia     = getUserMedia;
	navigator.mediaDevices.enumerateDevices = enumerateDevices;

	// Restore Callback support
	if (!doNotRestoreCallbacksSupport) {
		restoreCallbacksSupport();
	}

	window.RTCPeerConnection                = RTCPeerConnection;
	window.webkitRTCPeerConnection          = RTCPeerConnection;
	window.RTCSessionDescription            = RTCSessionDescription;
	window.RTCIceCandidate                  = RTCIceCandidate;
	window.MediaStream                      = MediaStream;
	window.webkitMediaStream                = MediaStream;
	window.MediaStreamTrack                 = MediaStreamTrack;
}

function dump() {
	exec(null, null, 'iosrtcPlugin', 'dump', []);
}
