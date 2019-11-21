import Foundation
import AVFoundation


/**
 * Doc: https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVCaptureDevice_Class/index.html
 */

struct MediaDeviceInfo {
	let deviceId, groupId, kind, label: String
	init(deviceId: String, kind: String, label: String) {
		self.deviceId = deviceId
		self.groupId = ""
		self.kind = kind
		self.label = label
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}

class PluginEnumerateDevices {
	class func call(_ callback: (_ data: NSDictionary) -> Void) {
		NSLog("PluginEnumerateDevices#call()")
		
		let audioDevices: [MediaDeviceInfo] = getAllAudioDevices()
		let videoDevices: [MediaDeviceInfo] = getAllVideoDevices()
		let allDevices = videoDevices + audioDevices;
		
		let json: NSMutableDictionary = [
			"devices": NSMutableArray()
		]
		
		// Casting to NSMutableDictionary
		for device: MediaDeviceInfo in allDevices {
			(json["devices"] as! NSMutableArray).add([
				"deviceId": device.deviceId,
				"kind": device.kind,
				"label": device.label,
				"groupId": device.groupId
			])
		}
		
		print("DEVICES => ", json)
		callback(json as NSDictionary)
	}
}

fileprivate func getAllVideoDevices() -> [MediaDeviceInfo] {
	
	var videoDevicesArr : [MediaDeviceInfo] = []
	let videoDevices: [AVCaptureDevice] = AVCaptureDevice.DiscoverySession.init(
		deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDualCamera],
		mediaType: AVMediaType.video,
		position: AVCaptureDevice.Position.unspecified
	).devices
	
	for device: AVCaptureDevice in videoDevices {
		var facing: String
		var facingLabel: String;
		let hasAudio = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.audio)))
		let hasVideo = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
		
		switch device.position {
		case AVCaptureDevice.Position.unspecified:
			facing = "unknown"
			facingLabel = "";
		case AVCaptureDevice.Position.back:
			facing = "back"
			facingLabel = "Back Camera"
		case AVCaptureDevice.Position.front:
			facing = "front"
			facingLabel = "Front Camera"
		}
		
		if device.isConnected == false || (hasAudio == false && hasVideo == false) {
			continue
		}
		
		NSLog("- device [uniqueID:'%@', localizedName:'%@', facing:%@, audio:%@, video:%@, connected:%@]",
			String(device.uniqueID), String(device.localizedName), String(facing),
			String(hasAudio), String(hasVideo), String(device.isConnected))
		
		if hasAudio == false {
			// Add English facingLabel suffix if localizedName does not match for facing detection using label
			let deviceLabel = device.localizedName.contains(facingLabel) ?
					device.localizedName : device.localizedName + " (" + facingLabel + ")";
			
			let device = MediaDeviceInfo(
				deviceId: device.uniqueID,
				kind: "videoinput",
				label: deviceLabel
			)
				
			// Put Front devices at beginning of the videoDevicesArr
			if (facing == "front") {
				// Simple Swift 4 array unshift
				let videoDevicesArrFirst : [MediaDeviceInfo] = [device]
				videoDevicesArr = videoDevicesArrFirst + videoDevicesArr;
			} else {
				videoDevicesArr.append(device)
			}
		}
	}
	
	return videoDevicesArr
}

// Getter function inserted by get all audio devices connected
fileprivate func getAllAudioDevices() -> [MediaDeviceInfo] {

	let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
	var audioDevicesArr : [MediaDeviceInfo] = []
	let audioInputDevices: [AVAudioSessionPortDescription] = audioSession.availableInputs!
	var bluetoothDevice: AVAudioSessionPortDescription? = nil
	var isBluetoothConnected : Bool = false
	var wiredDevice: AVAudioSessionPortDescription? = nil
	var isWiredConnected : Bool = false
	var builtMicDevice: AVAudioSessionPortDescription? = nil
	
	for audioInput in audioInputDevices {
		
		let device = MediaDeviceInfo(
			deviceId: audioInput.uid,
			kind: "audioinput",
			label: audioInput.portName
		);
		
		audioDevicesArr.append(device)
		
		// Initialize audioInputSelected. Default Built-In Microphone
		if audioInput.portType == AVAudioSession.Port.builtInMic {
			builtMicDevice = audioInput
		}
		
		if audioInput.portType == .bluetoothHFP || audioInput.portType == .bluetoothA2DP {
			bluetoothDevice = audioInput
			isBluetoothConnected = true
		}
		
		if audioInput.portType == .usbAudio || audioInput.portType == .headsetMic {
			wiredDevice = audioInput
			isWiredConnected = true
		}
	}
	
	// Initialize audioInputSelected. Priority: [Wired - Wireless - Built-In Microphone]
	if isWiredConnected {
		PluginRTCAudioController.saveInputAudioDevice(inputDeviceUID: wiredDevice!.uid)
	} else if isBluetoothConnected {
		PluginRTCAudioController.saveInputAudioDevice(inputDeviceUID: bluetoothDevice!.uid)
	} else {
		PluginRTCAudioController.saveInputAudioDevice(inputDeviceUID: builtMicDevice!.uid)
	}
	return audioDevicesArr
}
