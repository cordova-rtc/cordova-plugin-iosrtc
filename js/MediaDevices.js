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
var EventTarget = require('./EventTarget'),
	exec = require('cordova/exec'),
	getUserMedia = require('./getUserMedia'),
	enumerateDevices = require('./enumerateDevices');

function MediaDevices(data) {
	//ondevicechange
	//enumerateDevices
	//getDisplayMedia
	//getSupportedConstraints
	//getUserMedia

	var self = this;
	var ondevicechange;

	// Make this an EventTarget.
	EventTarget.call(self);

	data = data || {};

	Object.defineProperty(this, 'ondevicechange', {
		get: () => ondevicechange || null,
		set: (handler) => { ondevicechange = handler; }
	});
	function onResultOK(data) {
		self.dispatchEvent(new Event(data.type));
		if (data.type === 'devicechange' && typeof ondevicechange === 'function') {
			ondevicechange();
		}
	}
	exec(onResultOK, null, 'iosrtcPlugin', 'MediaDevices_setListener', []);
}

MediaDevices.prototype = Object.create(EventTarget.prototype);
MediaDevices.prototype.constructor = MediaDevices;

MediaDevices.prototype.getUserMedia = function (constraints) {
	return getUserMedia(constraints);
};

MediaDevices.prototype.enumerateDevices = function () {
	return enumerateDevices();
};

MediaDevices.prototype.getSupportedConstraints = function () {
	return {
		// Supported
		height: true,
		width: true,
		deviceId: true,
		frameRate: true,
		sampleRate: true,
		aspectRatio: true,
		// Not Supported
		autoGainControl: false,
		brightness: false,
		channelCount: false,
		colorTemperature: false,
		contrast: false,
		echoCancellation: false,
		exposureCompensation: false,
		exposureMode: false,
		exposureTime: false,
		facingMode: true,
		focusDistance: false,
		focusMode: false,
		groupId: false,
		iso: false,
		latency: false,
		noiseSuppression: false,
		pointsOfInterest: false,
		resizeMode: false,
		sampleSize: false,
		saturation: false,
		sharpness: false,
		torch: false,
		whiteBalanceMode: false,
		zoom: false
	};
};
