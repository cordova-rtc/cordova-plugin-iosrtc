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
	exec = require('cordova/exec'),
	videoElementsHandler = require('./videoElementsHandler');


/**
 * Expose the iosrtc object.
 */
module.exports = {
	// Expose WebRTC classes and functions.
	getUserMedia:          require('./getUserMedia'),
	getMediaDevices:       require('./getMediaDevices'),
	RTCPeerConnection:     require('./RTCPeerConnection'),
	RTCSessionDescription: require('./RTCSessionDescription'),
	RTCIceCandidate:       require('./RTCIceCandidate'),
	MediaStreamTrack:      require('./MediaStreamTrack'),

	// Expose a function to refresh current videos rendering a MediaStream.
	refreshVideos:         refreshVideos,

	// Expose a function to pollute window and naigator namespaces.
	polluteGlobals:        polluteGlobals,

	// Expose the rtcninjaPlugin module.
	rtcninjaPlugin:        require('./rtcninjaPlugin'),

	// Expose the debug module.
	debug:                 require('debug'),

	// TMP: Debug function to see what happens internally.
	dump:                  dump
};


// Observe video elements.
document.addEventListener('deviceready', function () {
	// Let the MediaStream class and the videoElementsHandler share same MediaStreams container.
	require('./MediaStream').setMediaStreams(mediaStreams);
	videoElementsHandler(mediaStreams, mediaStreamRenderers);
});


function refreshVideos() {
	var id;

	for (id in mediaStreamRenderers) {
		if (mediaStreamRenderers.hasOwnProperty(id)) {
			mediaStreamRenderers[id].refresh();
		}
	}
}


function polluteGlobals() {
	navigator.getUserMedia       = require('./getUserMedia');
	window.RTCPeerConnection     = require('./RTCPeerConnection');
	window.RTCSessionDescription = require('./RTCSessionDescription');
	window.RTCIceCandidate       = require('./RTCIceCandidate');
	window.MediaStreamTrack      = require('./MediaStreamTrack');
}


function dump() {
	exec(null, null, 'iosrtcPlugin', 'dump', []);
}

