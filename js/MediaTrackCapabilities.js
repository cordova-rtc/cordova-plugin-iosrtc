/**
 * Expose the MediaTrackSettings class.
 */
module.exports = MediaTrackCapabilities;

// Ref https://www.w3.org/TR/mediacapture-streams/#dom-mediatrackcapabilities
function MediaTrackCapabilities(data) {
	data = data || {};

	this.deviceId = data.deviceId;
}
