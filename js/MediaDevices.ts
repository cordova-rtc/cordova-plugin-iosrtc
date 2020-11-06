/**
 * Spec: https://w3c.github.io/mediacapture-main/#dom-mediadevices
 */
import { EventTargetShim } from './EventTarget';
import { getUserMedia } from './getUserMedia';
import { enumerateDevices } from './enumerateDevices';

export class MediaDevicesShim extends EventTargetShim implements MediaDevices {
	getUserMedia = getUserMedia;
	enumerateDevices = enumerateDevices;

	getSupportedConstraints() {
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
	}

	/**
	 * Additional, unimplemented members
	 */
	ondevicechange = null;
	//getDisplayMedia
}
