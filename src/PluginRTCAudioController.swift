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
    
    static func initAudioDevices() -> Void {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                AVAudioSession.Category.playAndRecord,
                mode: AVAudioSession.Mode.default,
                options: .allowBluetooth
            )
            try audioSession.setActive(true)
        } catch  {
            print("Error messing with audio session: \(error)")
        }
    }
    
    //
    // Audio Input
    //
    
    static private var audioInputSelected: AVAudioSessionPortDescription? = nil
    
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
    static func setInputAudioDevice() -> Void {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setPreferredInput(PluginRTCAudioController.audioInputSelected)
        } catch {
            NSLog("PluginRTCAudioController:setInputAudioDevice: Error setting audioSession preferred input.")
        }
    }

    //
    // Audio Output
    //
    
    private var speakerEnabled: Bool = false
    private var recordEnabled: Bool = false
    
    init() {
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
            NSLog("PluginRTCAudioController#audioRouteChangeListener() | headphone pulled out -> restore state speakerEnabled: %@", speakerEnabled ? "true" : "false")
            self.setOutputSpeakerIfNeed(enabled: speakerEnabled)
        default:
            break
        }
    }
    
    func setOutputSpeakerIfNeed(enabled: Bool) {
        
        speakerEnabled = enabled
        
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        
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
                        self.selectAudioOutputSpeaker()
                    } else {
                        self.selectAudioOutputEarpiece();
                    }
                }
            }
        } else {
            NSLog("PluginRTCAudioController#setOutputSpeakerIfNeed() | requires connection to device")
        }
    }
    
    func selectAudioOutputSpeaker() {
        // Enable speaker
        NSLog("PluginRTCAudioController#selectAudioOutputSpeaker()")
        
        do {
            let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                AVAudioSession.Category.playAndRecord,
                mode: AVAudioSession.Mode.default,
                options: .allowBluetooth
            )
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            NSLog("PluginRTCAudioController#selectAudioOutputSpeaker() | ERROR \(error)")
        };
    }
    
    func selectAudioOutputEarpiece() {
        // Disable speaker, switched to default
        NSLog("PluginRTCAudioController#selectAudioOutputEarpiece()")
        
        do {
            let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                AVAudioSession.Category.playAndRecord,
                mode: AVAudioSession.Mode.default,
                options: .allowBluetooth
            )
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        } catch {
            NSLog("PluginRTCAudioController#selectAudioOutputEarpiece() | ERROR \(error)")
        };
    }
}
