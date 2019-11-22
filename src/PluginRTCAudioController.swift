//
//  AudioOutputController.swift
//  StreamingDemo
//
//  Created by ows on 6/11/17.
//
//

import Foundation
import AVFoundation

class PluginRTCAudioController {
	
	static private var audioCategory = AVAudioSession.Category.playAndRecord
	static private var audioModeDefault = AVAudioSession.Mode.default
	
	/*
	 This mode is intended for Voice over IP (VoIP) apps and can only be used with the playAndRecord category. When this mode is used, the device’s tonal equalization is optimized for voice and the set of allowable audio routes is reduced to only those appropriate for voice chat.

	  See: https://developer.apple.com/documentation/avfoundation/avaudiosession/mode/1616455-voicechat
	 */
	static private var audioMode = AVAudioSession.Mode.voiceChat
	
	static private var audioInputSelected: AVAudioSessionPortDescription? = nil
	
	//
	// Audio Input
	//
	
	static func initAudioDevices() -> Void {
		
		PluginRTCAudioController.setCategory()
		
		do {
			let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
			try audioSession.setActive(true)
		} catch  {
			print("Error messing with audio session: \(error)")
		}
	}
	
	static func setCategory() -> Void {
		// Enable speaker
		NSLog("PluginRTCAudioController#setCategory()")
		
		do {
			let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
			try audioSession.setCategory(
				PluginRTCAudioController.audioCategory,
				mode: PluginRTCAudioController.audioMode,
				options: .allowBluetooth
			)
		} catch {
			NSLog("PluginRTCAudioController#setCategory() | ERROR \(error)")
		};
	}
	
	// Setter function inserted by save specific audio device
	static func saveInputAudioDevice(inputDeviceUID: String) -> Void {
		let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
		let audioInput: AVAudioSessionPortDescription = audioSession.availableInputs!.filter({
			(value:AVAudioSessionPortDescription) -> Bool in
			return value.uid == inputDeviceUID
		})[0]
		
		PluginRTCAudioController.audioInputSelected = audioInput
	}
	
	// Setter function inserted by set specific audio device
	static func restoreInputOutputAudioDevice() -> Void {
		let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
		
		do {
			try audioSession.setPreferredInput(PluginRTCAudioController.audioInputSelected)
		} catch {
			NSLog("PluginRTCAudioController:restoreInputOutputAudioDevice: Error setting audioSession preferred input.")
		}
		
		PluginRTCAudioController.setOutputSpeakerIfNeed(enabled: speakerEnabled);
	}
	
	static func setOutputSpeakerIfNeed(enabled: Bool) {
		
		speakerEnabled = enabled
		
		let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
		let currentRoute = audioSession.currentRoute
		
		if currentRoute.outputs.count != 0 {
			for description in currentRoute.outputs {
				if (
					description.portType == AVAudioSession.Port.headphones ||
						description.portType == AVAudioSession.Port.bluetoothA2DP ||
							description.portType == AVAudioSession.Port.carAudio ||
								description.portType == AVAudioSession.Port.airPlay ||
									description.portType == AVAudioSession.Port.lineOut
				) {
					NSLog("PluginRTCAudioController#setOutputSpeakerIfNeed() | external audio output plugged in -> do nothing")
				} else {
					NSLog("PluginRTCAudioController#setOutputSpeakerIfNeed() | external audio pulled out")
					
					if (speakerEnabled) {
						do {
							try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
						} catch {
							NSLog("PluginRTCAudioController#setOutputSpeakerIfNeed() | ERROR \(error)")
						};
					}
				}
			}
		} else {
			NSLog("PluginRTCAudioController#setOutputSpeakerIfNeed() | requires connection to device")
		}
	}
	
	static func selectAudioOutputSpeaker() {
		// Enable speaker
		NSLog("PluginRTCAudioController#selectAudioOutputSpeaker()")
		
		speakerEnabled = true;
		
		setCategory()
		
		do {
			let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
			try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
		} catch {
			NSLog("PluginRTCAudioController#selectAudioOutputSpeaker() | ERROR \(error)")
		};
	}
	
	static func selectAudioOutputEarpiece() {
		// Disable speaker, switched to default
		NSLog("PluginRTCAudioController#selectAudioOutputEarpiece()")
		
		speakerEnabled = false;
		
		setCategory()
		
		do {
			let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
			try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
		} catch {
			NSLog("PluginRTCAudioController#selectAudioOutputEarpiece() | ERROR \(error)")
		};
	}

	//
	// Audio Output
	//
	
	static private var speakerEnabled: Bool = false
	
	init() {
		
		PluginRTCAudioController.initAudioDevices()
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.audioRouteChangeListener(_:)),
			name: AVAudioSession.routeChangeNotification,
			object: nil)
	}
	
	@objc dynamic fileprivate func audioRouteChangeListener(_ notification:Notification) {
		let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
		
		switch audioRouteChangeReason {
		case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
			NSLog("PluginRTCAudioController#audioRouteChangeListener() | headphone plugged in")
		case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
			NSLog("PluginRTCAudioController#audioRouteChangeListener() | headphone pulled out -> restore state speakerEnabled: %@", PluginRTCAudioController.speakerEnabled ? "true" : "false")
			PluginRTCAudioController.setOutputSpeakerIfNeed(enabled: PluginRTCAudioController.speakerEnabled)
		default:
			break
		}
	}
}
