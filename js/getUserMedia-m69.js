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

function isPositiveInteger(number) {
	return typeof number === 'number' && number >= 0 && number % 1 === 0;
}

function isPositiveFloat(number) {
	return typeof number === 'number' && number >= 0;
}


function getUserMedia(constraints) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('cordova.plugins.iosrtc.getUserMedia', arguments);

	debug('[original constraints:%o]', constraints);

	var
		audioRequested = false,
		videoRequested = false,
		newConstraints = {};

	if (
		typeof constraints !== 'object' ||
			(!constraints.hasOwnProperty('audio') && !constraints.hasOwnProperty('video'))
	) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" keys'));
		});
	}

	if (constraints.audio) {
		audioRequested = true;
	}

	if (constraints.video) {
		videoRequested = true;
	}

	// https://www.w3.org/TR/mediacapture-streams/
	// https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints
	// Example:
	//
	// getUserMedia({
	//  audio: {
	//  	deviceId: 'azer-asdf-zxcv',
	//  },
	//  video: {
	//  	deviceId: 'qwer-asdf-zxcv',
	//      aspectRatio: 1.777.
	//		facingMode: 'user',
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
		// Handle object video constraints
		newConstraints.video = {};

		// Get requested video deviceId.
		if (typeof constraints.video.deviceId === 'string') {
			newConstraints.video.deviceId = constraints.video.deviceId;

		// Also check sourceId (mangled by adapter.js).
		} else if (typeof constraints.video.sourceId === 'string') {
			newConstraints.video.deviceId = constraints.video.sourceId;

		// Also check deviceId.(exact|ideal)
		} else if (typeof constraints.video.deviceId === 'object') {
			newConstraints.video.deviceId = !!constraints.video.deviceId.exact ? 
												constraints.video.deviceId.exact : 
													constraints.video.deviceId.ideal;
			if (Array.isArray(newConstraints.videoDeviceId)) {
				newConstraints.video.deviceId = newConstraints.video.deviceId[0];
			}
		}

		// Get requested width min/max, exact.
		if (typeof constraints.video.width === 'object') {
			newConstraints.video.width = {};
			if (isPositiveInteger(constraints.video.width.min)) {
				newConstraints.video.width.min = constraints.video.width.min;
			}
			if (isPositiveInteger(constraints.video.width.max)) {
				newConstraints.video.width.max = constraints.video.width.max;
			}
			// TODO exact, ideal

		//
		} else if (isPositiveFloat(constraints.video.width)) {
			newConstraints.video.width = {
				min: constraints.video.width,
				max: constraints.video.width,
			};
		}

		// Get requested height min/max, exact.
		if (typeof constraints.video.height === 'object') {
			newConstraints.video.height = {};
			if (isPositiveInteger(constraints.video.height.min)) {
				newConstraints.video.height.min = constraints.video.height.min;
			}
			if (isPositiveInteger(constraints.video.height.max)) {
				newConstraints.video.height.max = constraints.video.height.max;
			}
			// TODO exact, ideal
		//
		} else if (isPositiveFloat(constraints.video.height)) {
			newConstraints.video.height = {
				min: constraints.video.height,
				max: constraints.video.height
			};
		}

		// Get requested frameRate min/max.
		if (typeof constraints.video.frameRate === 'object') {
			newConstraints.video.frameRate = {};
			if (isPositiveFloat(constraints.video.frameRate.min)) {
				newConstraints.video.frameRate.min = constraints.video.frameRate.min;
			}
			if (isPositiveFloat(constraints.video.frameRate.max)) {
				newConstraints.video.frameRate.max = constraints.video.frameRate.max;
			}
			// TODO exact, ideal
		//
		} else if (isPositiveFloat(constraints.video.frameRate)) {
			newConstraints.video.frameRate = {
				max: constraints.video.frameRate,
				min: constraints.video.frameRate
			};
		}

		// get aspectRatio (e.g 1.7777777777777777)
		if (isPositiveFloat(constraints.video.aspectRatio)) {
			newConstraints.video.aspectRatio = constraints.video.aspectRatio;
		}

		// get facingMode (e.g environment, user)
		if (typeof constraints.video.facingMode === 'string') {
			newConstraints.video.facingMode = constraints.video.facingMode;
		}
	}

	// Get audio constraints
	if (audioRequested) {
		// Handle object audio constraints
		newConstraints.audio = {};

		// Get requested audio deviceId.
		if (typeof constraints.audio.deviceId === 'string') {
			newConstraints.audio.deviceId = constraints.audio.deviceId;

		// Also check sourceId (mangled by adapter.js).
		} else if (typeof constraints.audio.sourceId === 'string') {
			newConstraints.audio.deviceId = constraints.audio.sourceId;

		// Also check deviceId.(exact|ideal)
		} else if (typeof constraints.audio.deviceId === 'object') {
			newConstraints.audio.deviceId = !!constraints.audio.deviceId.exact ? 
												constraints.audio.deviceId.exact : 
													constraints.audio.deviceId.ideal;

			if (Array.isArray(newConstraints.audio.deviceId)) {
				newConstraints.audio.deviceId = newConstraints.audio.deviceId[0];
			}
		}	
	}

	debug('[computed constraints:%o]', newConstraints);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			debug('getUserMedia() | success');
			var stream = MediaStream.create(data.stream);
			resolve(stream);
			// Emit "connected" on the stream.
			stream.emitConnected();
		}

		function onResultError(error) {
			debugerror('getUserMedia() | failure: %s', error);
			reject(new Errors.MediaStreamError('getUserMedia() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'getUserMedia', [newConstraints]);
	});
}