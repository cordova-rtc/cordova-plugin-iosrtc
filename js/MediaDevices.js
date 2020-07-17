/**
 * Expose the MediaDevices class.
 */
module.exports = MediaDevices;

/**
 * Spec: https://w3c.github.io/mediacapture-main/#dom-mediadevices
 */

/**
 * Dependencies.
 */
var
	EventTarget = require('./EventTarget'),
	getUserMedia = require('./getUserMedia'),
	enumerateDevices = require('./enumerateDevices');

function MediaDevices(data) {

	//ondevicechange
	//enumerateDevices
	//getDisplayMedia
	//getSupportedConstraints
	//getUserMedia

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(self);

	data = data || {};
}

MediaDevices.prototype = Object.create(EventTarget.prototype);
MediaDevices.prototype.constructor = MediaDevices;

MediaDevices.prototype.getUserMedia = function (constraints) {
	return getUserMedia(constraints);
};

MediaDevices.prototype.enumerateDevices = function () {
	return enumerateDevices();
};
