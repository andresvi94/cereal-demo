//
//  FrameManager.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import AVFoundation

final class FrameManger: NSObject,ObservableObject {
    static let shared = FrameManger()
    
    @Published var current: CVPixelBuffer?
    
    let videoOutputQueue = DispatchQueue(
        label: "com.andresvi94.VideoOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    private override init() {
        super.init()
        CameraManager.shared.set(self, queue: videoOutputQueue)
    }
}

extension FrameManger: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                self.current = buffer
            }
        }
    }
}
