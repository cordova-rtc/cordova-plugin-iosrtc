import debugBase from 'debug';
import { MediaDeviceInfoShim } from './MediaDeviceInfo';
import { detectDeprecatedCallbaksUsage } from './Errors';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:enumerateDevices');

interface EnumerateDevicesResponse {
	devices: MediaDeviceInfo[];
}

export function enumerateDevices(): Promise<MediaDeviceInfoShim[]> {
	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	// eslint-disable-next-line prefer-rest-params
	detectDeprecatedCallbaksUsage('cordova.plugins.iosrtc.enumerateDevices', arguments);

	return new Promise(function (resolve) {
		function onResultOK(data: EnumerateDevicesResponse) {
			debug('enumerateDevices() | success');
			resolve(getMediaDeviceInfos(data.devices));
		}

		exec(onResultOK, null, 'iosrtcPlugin', 'enumerateDevices', []);
	});
}

/**
 * Private API.
 */

function getMediaDeviceInfos(devices: MediaDeviceInfo[]) {
	debug('getMediaDeviceInfos() | [devices:%o]', devices);

	return devices.map((deviceInfo) => {
		return new MediaDeviceInfoShim(deviceInfo);
	});
}
