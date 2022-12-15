//
//  ContentViewModel.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import CoreImage

final class ContentViewModel: ObservableObject {
    @Published var frame: CGImage?
    @Published var cerealResult: CerealResult?
    @Published var error: Error?
    
    private let cerealClassification = CerealClassificationHelper.shared
    private let cerealDetect = CerealDetectionHelper.shared
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
                self.cerealClassification.didOutput(pixelBuffer: buffer)
                self.cerealDetect.didOutput(pixelBuffer: buffer)
                return image
            }
            .assign(to: &$frame)
        
        cerealClassification.$classResults
            .receive(on: RunLoop.main)
            .assign(to: &$cerealResult)
        
        cameraManager.$error
          .receive(on: RunLoop.main)
          .map { $0 }
          .assign(to: &$error)

    }
}
