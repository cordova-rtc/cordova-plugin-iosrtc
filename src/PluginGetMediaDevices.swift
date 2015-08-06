import Foundation
import AVFoundation


/**
 * Doc: https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVCaptureDevice_Class/index.html
 */


class PluginGetMediaDevices {
	class func call(callback: (data: NSDictionary) -> Void) {
		NSLog("PluginGetMediaDevices#call()")

		let devices = AVCaptureDevice.devices() as! Array<AVCaptureDevice>

		let json: NSMutableDictionary = [
			"devices": NSMutableDictionary()
		]

		for device: AVCaptureDevice in devices {
			var position: String
			let hasAudio = device.hasMediaType(AVMediaTypeAudio)
			let hasVideo = device.hasMediaType(AVMediaTypeVideo)

			switch device.position {
			case AVCaptureDevicePosition.Unspecified:
				position = "unknown"
			case AVCaptureDevicePosition.Back:
				position = "back"
			case AVCaptureDevicePosition.Front:
				position = "front"
			}

			NSLog("- device [uniqueID:'\(device.uniqueID)', localizedName:'\(device.localizedName)', position:\(position), audio:\(hasAudio), video:\(hasVideo), connected:\(device.connected)")

			if device.connected == false || (hasAudio == false && hasVideo == false) {
				continue
			}

			(json["devices"] as! NSMutableDictionary)[device.uniqueID] = [
				"deviceId": device.uniqueID,
				"kind": hasAudio ? "audio" : "video",
				"label": device.localizedName
			]
		}

		callback(data: json)
	}
}
