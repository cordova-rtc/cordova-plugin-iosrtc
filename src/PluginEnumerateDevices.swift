import Foundation
import AVFoundation


/**
 * Doc: https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVCaptureDevice_Class/index.html
 */


class PluginEnumerateDevices {
	class func call(_ callback: (_ data: NSDictionary) -> Void) {
		NSLog("PluginEnumerateDevices#call()")

		let devices = AVCaptureDevice.devices()

		let json: NSMutableDictionary = [
			"devices": NSMutableDictionary()
		]

		for device: AVCaptureDevice in devices {
			var facing: String
			let hasAudio = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.audio)))
			let hasVideo = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))

			switch device.position {
			case AVCaptureDevice.Position.unspecified:
				facing = "unknown"
			case AVCaptureDevice.Position.back:
				facing = "back"
			case AVCaptureDevice.Position.front:
				facing = "front"
			}

			NSLog("- device [uniqueID:'%@', localizedName:'%@', facing:%@, audio:%@, video:%@, connected:%@]",
				String(device.uniqueID), String(device.localizedName), String(facing),
				String(hasAudio), String(hasVideo), String(device.isConnected))

			if device.isConnected == false || (hasAudio == false && hasVideo == false) {
				continue
			}

			(json["devices"] as! NSMutableDictionary)[device.uniqueID] = [
				"deviceId": device.uniqueID,
				"kind": hasAudio ? "audioinput" : "videoinput",
				"label": device.localizedName,
				"facing": facing
			]
		}

		callback(json)
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}
