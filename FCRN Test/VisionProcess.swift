//
//  VisionProcess.swift
//  FCRN Test
//
//  Created by Ayush Nayak on 1/8/21.
//

import AVKit
import Vision
import CoreML
import Foundation
import AVFoundation

// MARK: Structs

struct ClassificationReturn {
    var confidence: Double = 0.0
    var identifier: String = ""
    var boundingBox: CGRect
}

struct AudioLink {
    var TotalDist: Double = 0.0
    var Members = 1
    var Identifier: String
    var Area: Int = 0 // 0 = left, 1 = middle, 2 = right
}

struct Persistent {
    var Distance: Double = 0.0
    var Identifier: String = ""
    var BoundingBox: CGRect
    var Confidence: Double = 0.0
    var AbstractionNum: Int
}

// MARK: Functions


public func betaConvertTooPixels(box: CGRect) -> Array<Int> {
    
    // Probably Incorrect
    
    let newMinX: Int = Int(box.minX * 128.0)
    let newMaxX: Int = Int(box.maxX * 128.0)
    let newMinY: Int = Int(box.minY * 160.0)
    let newMaxY: Int = Int(box.maxY * 160.0)

    return [newMinX, newMinY, newMaxX, newMaxY]
}

public func averageRectangle(ret: Array<Int>, maze: Array<Array<Double>>) -> Double {
    let minX = ret[0]
    let minY = ret[1]
    let maxX = ret[2]
    let maxY = ret[3]
    
    
    // convertedHeatmap: 128x160 matrix of greyscale values (doubles)
    // For Each MaxY to MinY
    
    // Convert these if array in
    /*
    XXX
    XYX
    ZZZ
    [[XXX],[XYX],[ZZZ]]
     */
    let convertedMaxY = 160-maxY
    let convertedMinY = 160-minY
    var count: Double = 0.0
    var totalAvg: Double = 0.0
    for list in convertedMaxY...(convertedMinY - 1) {
        for item in minX...maxX {
            count += 1.0
            totalAvg += maze[list][item] // TODO: FIX THIS!
        }
    }
    
    let avg: Double = totalAvg / count
    
    return avg
}

public func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
        return
    }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    // Process the recognized strings.
    print(recognizedStrings)
}

func convert(cmage:CIImage) -> UIImage
{
     let context:CIContext = CIContext.init(options: nil)
     let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
     let image:UIImage = UIImage.init(cgImage: cgImage)
     return image
}

func convertTo2DArray(from heatmaps: MLMultiArray) -> (Array<Array<Double>>) {
    guard heatmaps.shape.count >= 3 else {
        print("heatmap's shape is invalid. \(heatmaps.shape)")
        return ([])
    }
    let _/*keypoint_number*/ = heatmaps.shape[0].intValue
    let heatmap_w = heatmaps.shape[1].intValue
    let heatmap_h = heatmaps.shape[2].intValue

    var convertedHeatmap: Array<Array<Double>> = Array(repeating: Array(repeating: 0.0, count: heatmap_w), count: heatmap_h)

    var minimumValue: Double = Double.greatestFiniteMagnitude
    var maximumValue: Double = -Double.greatestFiniteMagnitude

    for i in 0..<heatmap_w {
        for j in 0..<heatmap_h {
            let index = i * (heatmap_h) + j
            let confidence = heatmaps[index].doubleValue
            guard confidence > 0 else { continue }
            convertedHeatmap[j][i] = confidence

            if minimumValue > confidence {
                minimumValue = confidence
            }
            if maximumValue < confidence {
                maximumValue = confidence
            }
        }
    }

    let minmaxGap = maximumValue - minimumValue

    for i in 0..<heatmap_w {
        for j in 0..<heatmap_h {
            convertedHeatmap[j][i] = (convertedHeatmap[j][i] - minimumValue) / minmaxGap
        }
    }


    return (convertedHeatmap)
}
