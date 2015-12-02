/**
 * Expose the enumerateDevices function.
 */
module.exports = enumerateDevices;


/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:enumerateDevices'),
	exec = require('cordova/exec'),
	MediaDeviceInfo = require('./MediaDeviceInfo');


function enumerateDevices() {
	debug('');

	var isPromise,
		callback;

	if (typeof arguments[0] !== 'function') {
		isPromise = true;
	} else {
		isPromise = false;
		callback = arguments[0];
	}

	if (isPromise) {
		return new Promise(function (resolve) {
			function onResultOK(data) {
				debug('enumerateDevices() | success');
				resolve(getMediaDeviceInfos(data.devices));
			}

			exec(onResultOK, null, 'iosrtcPlugin', 'enumerateDevices', []);
		});
	}

	function onResultOK(data) {
		debug('enumerateDevices() | success');
		callback(getMediaDeviceInfos(data.devices));
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'enumerateDevices', []);
}


/**
 * Private API.
 */


function getMediaDeviceInfos(devices) {
	debug('getMediaDeviceInfos() | [devices:%o]', devices);

	var id,
		mediaDeviceInfos = [];

	for (id in devices) {
		if (devices.hasOwnProperty(id)) {
			mediaDeviceInfos.push(new MediaDeviceInfo(devices[id]));
		}
	}

	return mediaDeviceInfos;
}
