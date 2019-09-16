//
//  AudioOutputController.swift
//  StreamingDemo
//
//  Created by ows on 6/11/17.
//
//

import Foundation
import AVFoundation

class PluginRTCAudioOutputController {
    private var speakerEnabled: Bool = false
    private var recordEnabled: Bool = false
    
    init(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.audioRouteChangeListener(_:)),
            name: NSNotification.Name.AVAudioSessionRouteChange,
            object: nil)
    }
    
    dynamic fileprivate func audioRouteChangeListener(_ notification:Notification) {
        let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        
        switch audioRouteChangeReason {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable.rawValue:
            print("headphone plugged in")
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue:
            print("headphone pulled out -> restore state speakerEnabled: %@ %@", speakerEnabled, recordEnabled)
            self.setOutputSpeakerIfNeed(enabled:speakerEnabled, needRecord:recordEnabled)
        default:
            break
        }
    }
    
    func setOuputAudioMode(speaker: Bool, record: Bool){
        self.speakerEnabled = speaker
        self.recordEnabled = record
        
        self.setOutputSpeakerIfNeed(enabled:speaker, needRecord:record)
    }
    
    private func setOutputSpeakerIfNeed(enabled: Bool, needRecord: Bool) {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        
        if currentRoute.outputs.count != 0 {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    //headphonePluggedInStateImageView.image = headphonePluggedInImage
                    print("headphone plugged in -> do nothing")
                } else {
                    //headphonePluggedInStateImageView.image = headphonePulledOutImage
                    self.setAudioOutputSpeaker(enabled: enabled, needRecord: needRecord)
                    print("headphone pulled out")
                }
            }
        } else {
            //headphonePluggedInStateImageView.image = deviceRequiredImage
            print("requires connection to device")
            self.setAudioOutputSpeaker(enabled: enabled, needRecord: needRecord)
        }
    }
    
    private func setAudioOutputSpeaker(enabled: Bool, needRecord: Bool) {
        //Needs to be Record or PlayAndRecord to use audioRouteOverride:
        if needRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            } catch {
                NSLog("iosrtcPlugin#selectAudioOutputSpeaker() | ERROR \(error)")
            };
            
        }
        else {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch {
                NSLog("iosrtcPlugin#selectAudioOutputSpeaker() | ERROR \(error)")
            };
        }
        //set the audioSession override
        if enabled {
            // Enable speaker
            NSLog("iosrtcPlugin#selectAudioOutputSpeaker()")
            
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch {
                NSLog("iosrtcPlugin#selectAudioOutputSpeaker() | ERROR \(error)")
            };
            
        }
        else {
            // Disable speaker, switched to default
            NSLog("iosrtcPlugin#selectAudioOutputEarpiece()")
            
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            } catch {
                NSLog("iosrtcPlugin#selectAudioOutputEarpiece() | ERROR \(error)")
            };
        }
    }
}
