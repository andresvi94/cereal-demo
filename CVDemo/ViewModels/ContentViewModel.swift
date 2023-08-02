//
//  ContentViewModel.swift
//  CVDemo
//
//  Created by Andres Vinueza on 7/31/23.
//

import CoreImage

final class ContentViewModel: ObservableObject {
    @Published var frame: CGImage?
    @Published var overlay: CGImage?
    @Published var error: Error?
    
    private let objectDetect = ObjectDetectionHelper.shared
    private let frameManager = FrameManger.shared
    private let cameraManager = CameraManager.shared

    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                let image = CGImage.create(from: buffer)
                self.objectDetect.didOutput(pixelBuffer: buffer)
                return image
            }
            .assign(to: &$frame)

        objectDetect.$image
            .dropFirst()
            .receive(on: RunLoop.main)
            .assign(to: &$overlay)
        
        
        cameraManager.$error
          .receive(on: RunLoop.main)
          .map { $0 }
          .assign(to: &$error)

    }
    
    func updateConfidence(with value: Float) {
        objectDetect.minimumScore = value
    }
}
