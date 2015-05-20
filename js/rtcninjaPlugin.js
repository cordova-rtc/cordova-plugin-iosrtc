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
		RTCPeerConnection:     require('./RTCPeerConnection'),
		RTCSessionDescription: require('./RTCSessionDescription'),
		RTCIceCandidate:       require('./RTCIceCandidate'),
		MediaStreamTrack:      require('./MediaStreamTrack'),
		getMediaDevices:       require('./getMediaDevices'),
		attachMediaStream:     attachMediaStream,
		canRenegotiate:        true
	}
};


function attachMediaStream(element, stream) {
	element.src = URL.createObjectURL(stream);
	return element;
}
