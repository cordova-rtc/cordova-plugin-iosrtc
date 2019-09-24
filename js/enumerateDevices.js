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
	MediaDeviceInfo = require('./MediaDeviceInfo'),
	Errors = require('./Errors');


function enumerateDevices() {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('cordova.plugins.iosrtc.enumerateDevices', arguments);

	return new Promise(function (resolve) {
		function onResultOK(data) {
			debug('enumerateDevices() | success');
			resolve(getMediaDeviceInfos(data.devices));
		}

		exec(onResultOK, null, 'iosrtcPlugin', 'enumerateDevices', []);
	});
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
