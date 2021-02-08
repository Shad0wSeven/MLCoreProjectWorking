//
//   AudioReturn.swift
//  FCRN Test
//
//  Created by Ayush Nayak on 1/9/21.
//

import Foundation
import AVKit
import AVFoundation
import Vision
import CoreML

var player: AVAudioPlayer?
public func testSound() {
    guard let url = Bundle.main.url(forResource: "AudioTest", withExtension: "mp3") else { return }

    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)

        /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

        /* iOS 10 and earlier require the following line:
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

        guard let player = player else { return }

        player.play()

    } catch let error {
        print(error.localizedDescription)
    }
}

public func TTS(query: String) {
    let utterance = AVSpeechUtterance(string: query)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    let synthesizer = AVSpeechSynthesizer()
    synthesizer.speak(utterance)
}

func queryToString(query: AudioLink) -> String {
    var toReturn: String = ""
    
    if query.TotalDist / Double(query.Members) < 0.2 {
        toReturn.append(" close")
    }
    toReturn.append(query.Identifier)
    if query.Area == 0 {
        toReturn.append(" to the left")
    } else if query.Area == 1 {
        toReturn.append(" up ahead")
    } else {
        toReturn.append(" to the right")
    }
    return toReturn
}

public func playSound(ID: Int) {
    
    print("Played Sound \(ID)")
}
