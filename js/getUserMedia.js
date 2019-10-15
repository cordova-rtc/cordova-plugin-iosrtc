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
		newConstraints = {
			audio: false,
			video: false
		};

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

		// Handle Stupid not up-to-date webrtc-adapter
		// Note: Firefox [38+] does support a subset of constraints with getUserMedia(), but not the outdated syntax that Chrome and Opera are using. 
		// The mandatory / optional syntax was deprecated a in 2014, and minWidth and minHeight the year before that.
		
		if (
			typeof constraints.video === 'object' &&
				(typeof constraints.video.optional === 'object' || 
					typeof constraints.video.mandatory === 'object')
		) {

			if (
				typeof constraints.video.optional === 'object'
			) {
				if (typeof constraints.video.optional.sourceId === 'string') {
					newConstraints.videoDeviceId = constraints.video.optional.sourceId;
				} else if (
					Array.isArray(constraints.video.optional) &&
						typeof constraints.video.optional[0] === 'object' &&
							typeof constraints.video.optional[0].sourceId === 'string'
				) {
					newConstraints.videoDeviceId = constraints.video.optional[0].sourceId;
				}
			} else if (
				constraints.video.mandatory && 
					typeof constraints.video.mandatory.sourceId === 'string'
			) {
				newConstraints.videoDeviceId = constraints.video.mandatory.sourceId;
			}

			// Only apply mandatory over optional
			var videoConstraints = constraints.video.mandatory || constraints.video.optional;
			videoConstraints = Array.isArray(videoConstraints) ? videoConstraints[0] : videoConstraints; 

			if (isPositiveInteger(videoConstraints.minWidth)) {
				newConstraints.video.videoMinWidth = videoConstraints.minWidth;
			}

			if (isPositiveInteger(videoConstraints.minHeight)) {
				newConstraints.video.videoMinHeight = videoConstraints.minHeight;
			}
			
			if (isPositiveFloat(videoConstraints.minFrameRate)) {
				newConstraints.videoMinFrameRate = parseFloat(videoConstraints.minFrameRate, 10);
			}

			if (isPositiveFloat(videoConstraints.maxFrameRate)) {
				newConstraints.videoMaxFrameRate = parseFloat(videoConstraints.maxFrameRate, 10);
			}
		}

		// Handle getUserMedia proper spec

		// Get requested video deviceId.
		if (typeof constraints.video.deviceId === 'string') {
			newConstraints.videoDeviceId = constraints.video.deviceId;
		// Also check sourceId (mangled by adapter.js).
		} else if (typeof constraints.video.sourceId === 'string') {
			newConstraints.videoDeviceId = constraints.video.sourceId;
		} else if (typeof constraints.video.deviceId === 'object') {
			newConstraints.videoDeviceId = !!constraints.video.deviceId.exact ? constraints.video.deviceId.exact : constraints.video.deviceId.ideal;
			if (Array.isArray(newConstraints.videoDeviceId)) {
				newConstraints.videoDeviceId = newConstraints.videoDeviceId[0];
			}
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
				newConstraints.videoMinFrameRate = parseFloat(constraints.video.frameRate.min, 10);
			}
			if (isPositiveFloat(constraints.video.frameRate.max)) {
				newConstraints.videoMaxFrameRate = parseFloat(constraints.video.frameRate.max, 10);
			}
		} else if (isPositiveFloat(constraints.video.frameRate)) {
			newConstraints.videoMinFrameRate = parseFloat(constraints.video.frameRate, 10);
			newConstraints.videoMaxFrameRate = parseFloat(constraints.video.frameRate, 10);
		}
	}

	// Get audio constraints
	if (audioRequested) {

		// Handle Stupid not up-to-date webrtc-adapter
		// Note: Firefox [38+] does support a subset of constraints with getUserMedia(), but not the outdated syntax that Chrome and Opera are using. 
		// The mandatory / optional syntax was deprecated a in 2014, and minWidth and minHeight the year before that.
		if (
			typeof constraints.audio === 'object' &&
				(typeof constraints.audio.optional === 'object' || 
					typeof constraints.audio.mandatory === 'object')
		) {
			if (
				typeof constraints.audio.optional === 'object'
			) {
				if (typeof constraints.audio.optional.sourceId === 'string') {
					newConstraints.audioDeviceId = constraints.audio.optional.sourceId;
				} else if (
					Array.isArray(constraints.audio.optional) &&
						typeof constraints.audio.optional[0] === 'object' &&
							typeof constraints.audio.optional[0].sourceId === 'string'
				) {
					newConstraints.audioDeviceId = constraints.audio.optional[0].sourceId;
				}
			} else if (
				constraints.audio.mandatory && 
					typeof constraints.audio.mandatory.sourceId === 'string'
			) {
				newConstraints.audioDeviceId = constraints.audio.mandatory.sourceId;
			} 
		}

		// Get requested audio deviceId.
		if (typeof constraints.audio.deviceId === 'string') {
			newConstraints.audioDeviceId = constraints.audio.deviceId;
		// Also check sourceId (mangled by adapter.js).
		} else if (typeof constraints.audio.sourceId === 'string') {
			newConstraints.audioDeviceId = constraints.audio.sourceId;
		} else if (typeof constraints.audio.deviceId === 'object') {
			newConstraints.audioDeviceId = !!constraints.audio.deviceId.exact ? constraints.audio.deviceId.exact : constraints.audio.deviceId.ideal;
			if (Array.isArray(newConstraints.audioDeviceId)) {
				newConstraints.audioDeviceId = newConstraints.audioDeviceId[0];
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
