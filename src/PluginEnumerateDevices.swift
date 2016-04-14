import Foundation
import AVFoundation


/**
 * Doc: https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVCaptureDevice_Class/index.html
 */


class PluginEnumerateDevices {
	class func call(callback: (data: NSDictionary) -> Void) {
		NSLog("PluginEnumerateDevices#call()")

		let devices = AVCaptureDevice.devices() as! Array<AVCaptureDevice>

		let json: NSMutableDictionary = [
			"devices": NSMutableDictionary()
		]

		for device: AVCaptureDevice in devices {
			var facing: String
			let hasAudio = device.hasMediaType(AVMediaTypeAudio)
			let hasVideo = device.hasMediaType(AVMediaTypeVideo)

			switch device.position {
			case AVCaptureDevicePosition.Unspecified:
				facing = "unknown"
			case AVCaptureDevicePosition.Back:
				facing = "back"
			case AVCaptureDevicePosition.Front:
				facing = "front"
			}

			NSLog("- device [uniqueID:'%@', localizedName:'%@', facing:%@, audio:%@, video:%@, connected:%@]",
				String(device.uniqueID), String(device.localizedName), String(facing),
				String(hasAudio), String(hasVideo), String(device.connected))

			if device.connected == false || (hasAudio == false && hasVideo == false) {
				continue
			}

			(json["devices"] as! NSMutableDictionary)[device.uniqueID] = [
				"deviceId": device.uniqueID,
				"kind": hasAudio ? "audioinput" : "videoinput",
				"label": device.localizedName,
				"facing": facing
			]
		}

		callback(data: json)
	}
}
