//
//  ViewController.swift
//  FCRN Test
//
//  Created by Ayush Nayak on 12/8/20.
//

/*
 ||||||||\\\\\\\\\\
 ||             \\
 ||||||||      \\
       ||     \\
 ||||||||    \\
 */

import UIKit
import AVKit
import Vision
import CoreML
import AVFoundation


// Global Variables (May be bad practice, fix later)

let debug = false // Print Large Data or Not
var returnRequests = [ClassificationReturn]()
var matrixFCRN: Array<Array<Double>> = [[]]
var finishedReqFCRN: Array<Any> = []
var finishedReqYOLO: Array<Any> = []
var PersistentStorage: Array<Persistent> = []
var abstract = 0

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // UI Connections
    
    @IBOutlet var Label: UILabel!
    
    @IBOutlet var FPSLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
//        testSound()
        TTS(query: "this is a test of the audio system")
    
        // MARK: Capture Session

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo // Possibly Change FOV

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }

        captureSession.addInput(input)
        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        captureSession.addOutput(dataOutput)

    }

    // MARK: Capture Output and Process

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        abstract += 1
        
        // Time Elapsed
        let start = DispatchTime.now() // <<<<<<<<<< Start time
        
        // MARK: Distinguish Text
        // Perform Text handling
        
        // Converting Buffer to Image (orientation might be off)
        
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)! // FORCE UNWRAP!!!!!!
        let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let imageWrangler: UIImage = convert(cmage: ciimage)
        
        
        // Handling Text
        guard let cgImage = imageWrangler.cgImage else { return }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let requestText = VNRecognizeTextRequest(completionHandler: recognizeTextHandler(request:error:))
        
        do {
            try requestHandler.perform([requestText])
        } catch {
            print("Text Recognition Failed \(error)")
        }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        guard let model = try? VNCoreMLModel(for: FCRN(configuration: MLModelConfiguration.init()).model) else { return }
        guard let model2 = try? VNCoreMLModel(for: YOLOv3Tiny(configuration: MLModelConfiguration.init()).model) else { return }

        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            // MARK: FCRN

            if let results = finishedReq.results as? [VNCoreMLFeatureValueObservation],
                let heatmap = results.first?.featureValue.multiArrayValue {

                let start = CFAbsoluteTimeGetCurrent()
                let (convertedHeatmap) = convertTo2DArray(from: heatmap)
                let diff = CFAbsoluteTimeGetCurrent() - start
                
                matrixFCRN = convertedHeatmap
                finishedReqFCRN = finishedReq.results ?? []
                if debug {
                    print("Conversion to 2D Took \(diff) seconds")
                }


            } else {
                fatalError("Model failed to process image")
            }
        }
        let request2 = VNCoreMLRequest(model: model2) { (finishedReq, err) in
            
            // MARK: YOLOv3
            
            returnRequests.removeAll()
            finishedReqYOLO = finishedReq.results ?? []
            
            for observation in finishedReqYOLO where observation is VNRecognizedObjectObservation {
                guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                    
                }
                
                var currentRequest: ClassificationReturn! = ClassificationReturn(boundingBox: objectObservation.boundingBox)
                currentRequest.identifier = objectObservation.labels.first?.identifier ?? "NULL"
                currentRequest.confidence = Double(objectObservation.labels.first?.confidence ?? 0.0)
                returnRequests.append(currentRequest)
                

            }
            
        }
        if debug {
            print(finishedReqFCRN)
            print(matrixFCRN)
            print(finishedReqYOLO)
        }
        
        // MARK: Connect Values
        
        // -- Information about Values --
        //
        // convertedHeatmap: 128x160 matrix of greyscale values (doubles)
        // returnRequests: Struct, Identifier -> String, Confidence -> Double, BoundingBox -> CGRect
        
        // Step 1 Convert Bounding Box to Pixels
        
        var toOutput: String = ""
        for item in returnRequests {
            let returnArray: Array<Int> = betaConvertTooPixels(box: item.boundingBox)
            let value: Double = round(averageRectangle(ret: returnArray, maze: matrixFCRN)*10000)/10000
            let con: Double = round(item.confidence * 10000.0)/10000.0
            var toAdd: Persistent = Persistent(BoundingBox: item.boundingBox, AbstractionNum: abstract)
            toAdd.Distance = value
            toAdd.Identifier = item.identifier
            toAdd.Confidence = item.confidence
            PersistentStorage.append(toAdd)
            toOutput.append("Distance: \(value), OBJ: \(item.identifier), CON: \(con*100)% \n")
            print(toOutput)
            
        }

        let end = DispatchTime.now()   // <<<<<<<<<<   end time
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

        let FPS: Double = 1.0/Double(timeInterval)
        // MARK: Print to Storyboard
        DispatchQueue.main.async {
            self.Label.text = toOutput
            self.FPSLabel.text = "\(round(FPS*1000)/1000.0) FPS"
        }
        
        // Prune Persistent Storage, and handle audio events
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request, request2])
        
    }

}


// MARK: Extensions

extension ViewController {


}
