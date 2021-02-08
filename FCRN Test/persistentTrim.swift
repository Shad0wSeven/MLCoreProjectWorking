//
//  persistentTrim.swift
//  FCRN Test
//
//  Created by Ayush Nayak on 1/9/21.
//

import Foundation
import UIKit
import AVKit
import Vision
import CoreML
import AVFoundation

func trimPersistent(arr: Array<Persistent>, currentAbstract: Int, memory: Int) -> Array<Persistent> {
    var newArr: Array<Persistent> = arr
    // Trim ones older than memory Iterations and Under Confidence Level
    var pos: Int = 0
    for item in newArr {
        var toRemove: Bool = false
        if item.AbstractionNum <= (currentAbstract - memory) {
            toRemove = true
        }
        if item.Confidence <= 0.7 {
            toRemove = true
        }
        
        // Now remove any similars
        
        
        
        // TODO: REMOVE SIMILARS!
        
        if toRemove {
            newArr.remove(at: pos)
        }
        pos += 1
    }
    
    return newArr
    
}


func returnAverages(arr: Array<Persistent>) -> Array<AudioLink> {
    var toReturn: Array<AudioLink> = []
    for item in arr {
        var temp = AudioLink(Identifier: item.Identifier)
        // Now here, split into 3 thirds
        let coordinate = betaConvertTooPixels(box: item.BoundingBox).first
        if coordinate ?? 0 < 45 {
            // Left
            temp.Area = 0
        } else if coordinate ?? 0 < 90 {
            // Middle
            temp.Area = 1
        } else {
            // Right
            temp.Area = 2
        }
        temp.TotalDist += item.Distance
        
        // Make sure not dupe
        var id = 0
        for thing in toReturn {
            if thing.Area == temp.Area && temp.Identifier == thing.Identifier {
                temp.Members += thing.Members
                temp.TotalDist += thing.TotalDist
                toReturn.remove(at: id)
                toReturn.append(temp)
                break
            }
        id += 1
        }
        // Now Ready
    }
    return toReturn
}
