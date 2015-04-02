//
//  YepAudioService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class YepAudioService: NSObject {
    
    static let sharedManager = YepAudioService()

    var audioFileURL: NSURL?
    var audioRecorder: AVAudioRecorder?

    func prepareAudioRecorderWithFileURL(fileURL: NSURL, audioRecorderDelegate: AVAudioRecorderDelegate) {
        audioFileURL = fileURL

        let settings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 64000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        var error: NSError?
        audioRecorder = AVAudioRecorder(URL: fileURL, settings: settings as [NSObject : AnyObject], error: &error)

        if let error = error {
            println(error.localizedDescription)

        } else {
            if let audioRecorder = audioRecorder {
                audioRecorder.delegate = audioRecorderDelegate

                audioRecorder.meteringEnabled = true
                audioRecorder.prepareToRecord() // creates/overwrites the file at soundFileURL
            }
        }
    }

    func beginRecordWithFileURL(fileURL: NSURL, audioRecorderDelegate: AVAudioRecorderDelegate) {
        
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {

                self.prepareAudioRecorderWithFileURL(fileURL, audioRecorderDelegate: audioRecorderDelegate)

                if let audioRecorder = self.audioRecorder {

                    if (audioRecorder.recording){
                        audioRecorder.stop()

                    } else {
                        audioRecorder.record()
                        println("Audio Record did begin")
                    }
                }

            } else {
                println("Permission to record not granted")
            }
        })
    }
    
    func endRecord() {
        if let audioRecorder = audioRecorder {
            if (audioRecorder.recording){
                audioRecorder.stop()
            }
        }
    }
}
