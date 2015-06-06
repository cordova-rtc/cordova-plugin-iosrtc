/**
 * Expose the getUserMedia function.
 */
module.exports = getUserMedia;


/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:getUserMedia'),
	debugerror = require('debug')('iosrtc:ERROR:getUserMedia'),
	exec = require('cordova/exec'),
	MediaStream = require('./MediaStream'),
	Errors = require('./Errors');


debugerror.log = console.warn.bind(console);


function getUserMedia(constraints) {
	debug('[constraints:%o]', constraints);

	var isPromise,
		callback, errback,
		audioRequested = false,
		videoRequested = false,
		videoOptionalConstraints,
		videoMandatoryConstraints,
		videoDeviceId,
		newConstraints = {
			audio: false,
			video: false
		};

	if (typeof arguments[1] !== 'function') {
		isPromise = true;
	} else {
		isPromise = false;
		callback = arguments[1];
		errback = arguments[2];
	}

	if (
		typeof constraints !== 'object' ||
		(!constraints.hasOwnProperty('audio') && !constraints.hasOwnProperty('video'))
	) {
		if (isPromise) {
			return new Promise(function (resolve, reject) {
				reject(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" boolean fields'));
			});
		} else {
			if (typeof errback === 'function') {
				errback(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" boolean fields'));
			}
			return;
		}
	}

	if (constraints.audio) {
		audioRequested = true;
		newConstraints.audio = true;
	}
	if (constraints.video) {
		videoRequested = true;
		newConstraints.video = true;
	}

	// Example:
	//
	// getUserMedia({
	//  audio: true,
	//  video: {
	//  	optional: [
	//  		{ sourceId: 'qwe-asd-zxc-123' }
	//  	]
	//  }
	// });

	if (videoRequested && Array.isArray(constraints.video.optional)) {
		videoOptionalConstraints = constraints.video.optional;

		if (videoOptionalConstraints[0]) {
			videoDeviceId = videoOptionalConstraints[0].sourceId;

			if (typeof videoDeviceId === 'string') {
				newConstraints.videoDeviceId = videoDeviceId;
			}
		}
	}

	if (videoRequested && Array.isArray(constraints.video.mandatory)) {
		videoMandatoryConstraints = constraints.video.mandatory;

		if (videoMandatoryConstraints[0]) {
			videoDeviceId = videoMandatoryConstraints[0].sourceId;

			if (typeof videoDeviceId === 'string') {
				newConstraints.videoDeviceId = videoDeviceId;
			}
		}
	}

	if (isPromise) {
		return new Promise(function (resolve, reject) {
			function onResultOK(data) {
				debug('getUserMedia() | success');
				resolve(MediaStream.create(data.stream));
			}

			function onResultError(error) {
				debugerror('getUserMedia() | failure: %s', error);
				reject(new Errors.MediaStreamError('getUserMedia() failed: ' + error));
			}

			exec(onResultOK, onResultError, 'iosrtcPlugin', 'getUserMedia', [newConstraints]);
		});
	}

	function onResultOK(data) {
		debug('getUserMedia() | success');

		var stream = MediaStream.create(data.stream);

		callback(stream);

		// Emit "connected" on the stream.
		stream.emitConnected();
	}

	function onResultError(error) {
		debugerror('getUserMedia() | failure: %s', error);

		if (typeof errback === 'function') {
			errback(new Errors.MediaStreamError('getUserMedia() failed: ' + error));
		}
	}

	exec(onResultOK, onResultError, 'iosrtcPlugin', 'getUserMedia', [newConstraints]);
}
