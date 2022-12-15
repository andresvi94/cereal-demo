//
//  CGImageExtension.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import CoreGraphics
import VideoToolbox
import TensorFlowLiteTaskVision

extension CGImage {
    static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
        guard let pixelBuffer = cvPixelBuffer else {
            return nil
        }
        
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(
            pixelBuffer,
            options: nil,
            imageOut: &image)
        return image
    }
    
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)
        
        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel
        
        
        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
}

extension MLImage {
    static func create(from cvPixelBuffer: CVPixelBuffer?) -> MLImage? {
        guard let pixelBuffer = cvPixelBuffer else {
            return nil
        }
         
        // Previewed cereal_model.tflite with Netron to see image input size (224 x 224)
        let inputSize = 224.0
        guard let cgImage = CGImage.create(from: pixelBuffer),
              let resizedCGImage = cgImage.resize(size: CGSize(width: inputSize, height: inputSize)) else {
            return MLImage(pixelBuffer: pixelBuffer)
        }
       
        return MLImage(image: UIImage(cgImage: resizedCGImage))
    }
}

