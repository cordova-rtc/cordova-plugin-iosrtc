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


function isPositiveInteger(number) {
	return typeof number === 'number' && number >= 0 && number % 1 === 0;
}

function isPositiveFloat(number) {
	return typeof number === 'number' && number >= 0;
}


function getUserMedia(constraints) {
	debug('[original constraints:%o]', constraints);

	var
		isPromise,
		callback, errback,
		audioRequested = false,
		videoRequested = false,
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
				reject(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" keys'));
			});
		} else {
			if (typeof errback === 'function') {
				errback(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" keys'));
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
	//  	deviceId: 'qwer-asdf-zxcv',
	//  	width: {
	//  		min: 400,
	//  		max: 600
	//  	},
	//  	frameRate: {
	//  		min: 1.0,
	//  		max: 60.0
	//  	}
	//  }
	// });

	// Get video constraints
	if (videoRequested) {
		// Get requested video deviceId.
		if (typeof constraints.video.deviceId === 'string') {
			newConstraints.videoDeviceId = constraints.video.deviceId;
		}

		// Get requested min/max width.
		if (typeof constraints.video.width === 'object') {
			if (isPositiveInteger(constraints.video.width.min)) {
				newConstraints.videoMinWidth = constraints.video.width.min;
			}
			if (isPositiveInteger(constraints.video.width.max)) {
				newConstraints.videoMaxWidth = constraints.video.width.max;
			}
		}
		// Get requested min/max height.
		if (typeof constraints.video.height === 'object') {
			if (isPositiveInteger(constraints.video.height.min)) {
				newConstraints.videoMinHeight = constraints.video.height.min;
			}
			if (isPositiveInteger(constraints.video.height.max)) {
				newConstraints.videoMaxHeight = constraints.video.height.max;
			}
		}
		// Get requested min/max frame rate.
		if (typeof constraints.video.frameRate === 'object') {
			if (isPositiveFloat(constraints.video.frameRate.min)) {
				newConstraints.videoMinFrameRate = constraints.video.frameRate.min;
			}
			if (isPositiveFloat(constraints.video.frameRate.max)) {
				newConstraints.videoMaxFrameRate = constraints.video.frameRate.max;
			}
		} else if (isPositiveFloat(constraints.video.frameRate)) {
			newConstraints.videoMinFrameRate = constraints.video.frameRate;
			newConstraints.videoMaxFrameRate = constraints.video.frameRate;
		}
	}

	debug('[computed constraints:%o]', newConstraints);

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
