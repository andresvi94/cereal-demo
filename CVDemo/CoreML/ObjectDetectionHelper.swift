//
//  ObjectDetectionHelper.swift
//  CVDemo
//
//  Created by Andres Vinueza on 7/31/23.
//

import AVFoundation
import Foundation
import UIKit
import Vision

struct Detection {
    let box:CGRect
    let confidence:Float
    let label:String?
    let color:UIColor
}

final class ObjectDetectionHelper {
    
    static let shared = ObjectDetectionHelper()
    
    @Published var classResults: CerealResult?
    @Published var image: CGImage?
    private var vnRequest: VNCoreMLRequest?
    private var buffer: CVPixelBuffer?
    private var detectionOverlay = CALayer()
    
    private let detectQueue = DispatchQueue(label: "com.andresvi94.DetectQ")
    private var isDetectQueueBusy = false
    private var previousInferenceTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
    private let delayBetweenInferencesMs = 1000.0
    @Published var minimumScore: Float = 30.0
    private var videoSize = CGSize.zero
    private let colors:[UIColor] = {
        var colorSet: [UIColor] = []
        for _ in 0...80 {
            let color = UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1)
            colorSet.append(color)
        }
        return colorSet
    }()
    
    let ciContext = CIContext()
    var classes:[String] = []
    
    private init() {
        configure()
    }
    
    private func configure() {
        do {
            let model = try yolov8s().model
            guard let classes = model.modelDescription.classLabels as? [String] else {
                fatalError("Fatal error couldn't load YoloV8 classes")
            }
            
            self.classes = classes
            let vnModel = try VNCoreMLModel(for: model)
            self.vnRequest = VNCoreMLRequest(model: vnModel)
        } catch {
            fatalError("Fatal error couldn't load YoloV8 model")
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
        guard !self.isDetectQueueBusy else { return }
        
        detectQueue.async {
            self.buffer = pixelBuffer
            self.isDetectQueueBusy = true
            
            do {
                guard let pixelBuffer = pixelBuffer, let vnRequest = self.vnRequest else {
                    self.isDetectQueueBusy = false
                    return
                }
                
                if self.videoSize == CGSize.zero {
                    let cgImage = CGImage.create(from: pixelBuffer)
                    guard let width = cgImage?.width,
                          let height = cgImage?.height else {
                        self.isDetectQueueBusy = false
                        return
                    }
                    self.videoSize = CGSize(width: CGFloat(width), height: CGFloat(height))
                }
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
                try handler.perform([vnRequest])
                guard let results = vnRequest.results as? [VNRecognizedObjectObservation] else {
                    self.isDetectQueueBusy = false
                    return
                }
                
                var detections:[Detection] = []
                for result in results {
                    let flippedBox = CGRect(x: result.boundingBox.minX, y: 1 - result.boundingBox.maxY, width: result.boundingBox.width, height: result.boundingBox.height)
                    let box = VNImageRectForNormalizedRect(flippedBox, Int(self.videoSize.width), Int(self.videoSize.height))
                    
                    guard let label = result.labels.first?.identifier as? String,
                          let colorIndex = self.classes.firstIndex(of: label) else {
                        self.isDetectQueueBusy = false
                        return
                    }
                    let detection = Detection(box: box, confidence: result.confidence, label: label, color: self.colors[colorIndex])
                    detections.append(detection)
                }
                self.drawRectsOnImage(detections, pixelBuffer)
            } catch {
                self.isDetectQueueBusy = false
                print("Detection error: \(error)")
            }
        }
    }
    
    func drawRectsOnImage(_ detections: [Detection], _ pixelBuffer: CVPixelBuffer) {
        defer {
            self.isDetectQueueBusy = false
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
        let size = ciImage.extent.size
        guard let cgContext = CGContext(data: nil,
                                        width: Int(size.width),
                                        height: Int(size.height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: 4 * Int(size.width),
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return  }
        cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        for detection in detections {
            guard detection.confidence*100 > minimumScore else {
                continue
            }
            let invertedBox = CGRect(x: detection.box.minX, y: size.height - detection.box.maxY, width: detection.box.width, height: detection.box.height)
            if let labelText = detection.label {
                cgContext.textMatrix = .identity
                
                let text = "\(labelText) : \(round(detection.confidence*100))"
                
                let textRect  = CGRect(x: invertedBox.minX + size.width * 0.01, y: invertedBox.minY - size.width * 0.01, width: invertedBox.width, height: invertedBox.height)
                let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                
                let textFontAttributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: textRect.width * 0.1, weight: .bold),
                    NSAttributedString.Key.foregroundColor: detection.color,
                    NSAttributedString.Key.paragraphStyle: textStyle
                ]
                
                cgContext.saveGState()
                defer { cgContext.restoreGState() }
                let astr = NSAttributedString(string: text, attributes: textFontAttributes)
                let setter = CTFramesetterCreateWithAttributedString(astr)
                let path = CGPath(rect: textRect, transform: nil)
                
                let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
                cgContext.textMatrix = CGAffineTransform.identity
                CTFrameDraw(frame, cgContext)
                
                cgContext.setStrokeColor(detection.color.cgColor)
                cgContext.setLineWidth(9)
                cgContext.stroke(invertedBox)
            }
        }
        
        guard let newImage = cgContext.makeImage() else {
            self.isDetectQueueBusy = false
            return
        }
        self.image = newImage
    }
}
