//
//  CerealDetectionHelper.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import TensorFlowLiteTaskVision
import Vision

final class CerealDetectionHelper {
    
    static let shared = CerealDetectionHelper()
    
    @Published var classResults: CerealResult?
    private var detector: ObjectDetector?
    private var buffer: CVPixelBuffer?
    private var detectionOverlay = CALayer()
    
    private let detectQueue = DispatchQueue(label: "com.andresvi94.DetectQ")
    private var isDetectQueueBusy = false
    private var previousInferenceTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
    private let delayBetweenInferencesMs = 1000.0
    private let minimumScore: Float = 30.0
    
    private init() {
        configure()
    }
    
    private func configure() {
        //        let name = "best-int8"
        let name = "ssd_mobilenet_v1"
        guard let modelPath = Bundle.main.path(forResource: name, ofType: "tflite") else {
            print("Failed to load TFLite model")
            return
        }
        
        do {
            let options = ObjectDetectorOptions(modelPath: modelPath)
            options.classificationOptions.maxResults = 3
            detector = try ObjectDetector.detector(options: options)
        } catch {
            print("Failed to create TFLite model: \(error)")
        }
    }
    
    private func checkLastInferenceTime() -> Bool {
        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        
        let isGreaterThanDelay = (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs
        
        if isGreaterThanDelay {
            previousInferenceTimeMs = currentTimeMs
        }
        
        return isGreaterThanDelay
    }
    
    func didOutput(pixelBuffer: CVPixelBuffer?) {
        guard checkLastInferenceTime() else { return }
        guard !self.isDetectQueueBusy else { return }
        
        detectQueue.async {
            self.buffer = pixelBuffer
            self.isDetectQueueBusy = true
            let mlImage = MLImage.create(from: pixelBuffer)
            let result = self.classify(image: mlImage)
            self.classResults = result
            self.isDetectQueueBusy = false
        }
    }
    
    private func classify(image baseImage: MLImage?) -> CerealResult? {
        guard let mlImage = baseImage else {
            print("Failed to load Base iamge")
            return nil
        }
        
        do {
            let startDate = Date()
            let detectionResult = try detector?.detect(mlImage: mlImage)
            let interval = Date().timeIntervalSince(startDate) * 1000
            let time = String(format: "%.2f", interval) + "s"
            displayStringsForResults(with: detectionResult)
            
            return CerealResult(inferenceTime: time, classificationLabel: "0", classificationScore: "0")
        } catch {
            print("Failed to classify cereal: \(error)")
            return nil
        }
    }
    
    private func displayStringsForResults(with result:  DetectionResult?) {
        guard let displayResult = result, let pixelBuffer = self.buffer, displayResult.detections.count > 0 else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let detections = displayResult.detections
        
        
        guard !detections.isEmpty else { return }
        for detection in detections {
            guard let category = detection.categories.first else { continue }
//            debugPrint(category)
            let objectBounds = VNImageRectForNormalizedRect(detection.boundingBox, Int(width), Int(height))
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)

            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: "",
                                                            confidence: Float(0))
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
           let textLayer = CATextLayer()
           textLayer.name = "Object Label"
           let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
           let largeFont = UIFont(name: "Helvetica", size: 24.0)!
           formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
           textLayer.string = formattedString
           textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
           textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
           textLayer.shadowOpacity = 0.7
           textLayer.shadowOffset = CGSize(width: 2, height: 2)
           textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
           textLayer.contentsScale = 2.0 // retina rendering
           // rotate the layer into screen orientation and scale and mirror
           textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
           return textLayer
       }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
          let shapeLayer = CALayer()
          shapeLayer.bounds = bounds
          shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
          shapeLayer.name = "Found Object"
          shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
          shapeLayer.cornerRadius = 7
          return shapeLayer
      }
}
