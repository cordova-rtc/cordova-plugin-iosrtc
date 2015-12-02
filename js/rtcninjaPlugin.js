/**
 * Expose the rtcninjaPlugin object.
 */
module.exports = {
	isRequired: function () {
		return true;
	},

	isInstalled: function () {
		return true;
	},

	interface: {
		getUserMedia:          require('./getUserMedia'),
		enumerateDevices:      require('./enumerateDevices'),
		getMediaDevices:       require('./enumerateDevices'),  // TMP
		RTCPeerConnection:     require('./RTCPeerConnection'),
		RTCSessionDescription: require('./RTCSessionDescription'),
		RTCIceCandidate:       require('./RTCIceCandidate'),
		MediaStreamTrack:      require('./MediaStreamTrack'),
		attachMediaStream:     attachMediaStream,
		canRenegotiate:        true
	}
};


function attachMediaStream(element, stream) {
	element.src = URL.createObjectURL(stream);
	return element;
}
