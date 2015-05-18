/**
 * Dependencies.
 */
var exec = require('cordova/exec');


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
	MediaStreamRenderer:   require('./MediaStreamRenderer'),

	// Expose the rtcninjaPlugin module.
	rtcninjaPlugin:        require('./rtcninjaPlugin'),

	// Expose the debug module.
	debug:                 require('debug'),

	// TMP: Debug function to see what happens internally.
	dump:                  dump
};


function dump() {
	exec(null, null, 'iosrtcPlugin', 'dump', []);
}

