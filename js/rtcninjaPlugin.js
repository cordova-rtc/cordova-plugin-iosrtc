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
		RTCPeerConnection: require('./RTCPeerConnection'),
		RTCSessionDescription: require('./RTCSessionDescription'),
		RTCIceCandidate: require('./RTCIceCandidate'),
		canRenegotiate: true,
		getUserMedia: require('./getUserMedia'),
		getMediaDevices: require('./getMediaDevices')
	}
};
