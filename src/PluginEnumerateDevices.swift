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

var audioInputSelected: AVAudioSessionPortDescription? = nil

class PluginEnumerateDevices {
	class func call(_ callback: (_ data: NSDictionary) -> Void) {
		NSLog("PluginEnumerateDevices#call()")
		initAudioDevices()
		var audioDevices: [MediaDeviceInfo] = getAllAudioDevices()
		let devices: [AVCaptureDevice] = AVCaptureDevice.DiscoverySession.init( deviceTypes: [ AVCaptureDevice.DeviceType.builtInMicrophone, AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: nil, position: AVCaptureDevice.Position.unspecified).devices  
		let json: NSMutableDictionary = [
			"devices": NSMutableDictionary()
		]
		
		for device: AVCaptureDevice in devices {
			let hasAudio = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.audio)))
			let hasVideo = device.hasMediaType(AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
			
			NSLog("- device [uniqueID:'%@', localizedName:'%@', audio:%@, video:%@, connected:%@]",
				  String(device.uniqueID), String(device.localizedName),
				  String(hasAudio), String(hasVideo), String(device.isConnected))
			
			if device.isConnected == false || (hasAudio == false && hasVideo == false) {
				continue
			}
			
			if hasAudio == false {
				audioDevices.append(MediaDeviceInfo(deviceId: device.uniqueID, kind: "videoinput", label: device.localizedName))
			}
		}
		
		// Casting to NSMutableDictionary
		for device: MediaDeviceInfo in audioDevices {
			(json["devices"] as! NSMutableDictionary)[device.deviceId] = [
				"deviceId": device.deviceId,
				"kind": device.kind,
				"label": device.label,
				"groupId": device.groupId
			]
		}
		
		print("DEVICES => ", json)
		callback(json as NSDictionary)
	}
	
	// Setter function inserted by save specific audio device
	class func saveAudioDevice(inputDeviceUID: String) -> Void {
		let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
		let audioInput: AVAudioSessionPortDescription = audioSession.availableInputs!.filter({ (value:AVAudioSessionPortDescription) -> Bool in
			return value.uid == inputDeviceUID
		})[0]
		
		audioInputSelected = audioInput
	}
	
	// Setter function inserted by set specific audio device
	class func setPreferredInput() -> Void {
		let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
		
		//print("SETTING INPUT SELECTED: ", audioInputSelected!)
		
		do {
			try audioSession.setPreferredInput(audioInputSelected)
		} catch {
			print("Error setting audio device.")
		}
	}
}

// Getter function inserted by get all audio devices connected
fileprivate func getAllAudioDevices() -> [MediaDeviceInfo] {
	let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
	var audioDevicesArr : [MediaDeviceInfo] = []
	let audioInputDevices: [AVAudioSessionPortDescription] = audioSession.availableInputs!
	
	for audioInput in audioInputDevices {
		audioDevicesArr.append(MediaDeviceInfo(deviceId: audioInput.uid, kind: "audioinput", label: audioInput.portName))
		
		// Initialize audioInputSelected. Default Built-In Microphone
		if audioInput.portType == AVAudioSession.Port.builtInMic {
			PluginEnumerateDevices.saveAudioDevice(inputDeviceUID: audioInput.uid)
		}
	}
	return audioDevicesArr
}

fileprivate func initAudioDevices() -> Void {
	let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
	
	do {
		try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .allowBluetooth)
		try audioSession.setActive(true)
	} catch  {
		print("Error messing with audio session: \(error)")
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}
