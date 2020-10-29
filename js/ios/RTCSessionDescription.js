/**
 * Expose the RTCSessionDescription class.
 */
module.exports = RTCSessionDescription;


function RTCSessionDescription(data) {
	data = data || {};

	// Public atributes.
	this.type = data.type;
	this.sdp = data.sdp;
}
