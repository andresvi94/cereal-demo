//
//  CerealDetectionHelper.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//


import TensorFlowLiteTaskVision

struct CerealResult {
    let inferenceTime: String
    let classificationLabel: String?
    let classificationScore: String?
}

final class CerealClassificationHelper {
    
    static let shared = CerealClassificationHelper()
    
    @Published var classResults: CerealResult?
    private var classifier: ImageClassifier?
    
    private let inferenceQueue = DispatchQueue(label: "com.andresvi94.InferenceQ")
    private var isInferenceQueueBusy = false
    private var previousInferenceTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
    private let delayBetweenInferencesMs = 1000.0
    private let minimumScore: Float = 30.0
    
    private init() {
        configure()
    }
    
    private func configure() {
        let name = "cereal_model"
        guard let modelPath = Bundle.main.path(forResource: name, ofType: "tflite") else {
            print("Failed to load TFLite model")
            return
        }
        
        do {
            let classOptions = ImageClassifierOptions(modelPath: modelPath)
            classifier = try ImageClassifier.classifier(options: classOptions)
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
        guard !self.isInferenceQueueBusy else { return }
        
        inferenceQueue.async {
            self.isInferenceQueueBusy = true
            let mlImage = MLImage.create(from: pixelBuffer)
            let result = self.classify(image: mlImage)
            self.classResults = result
            self.isInferenceQueueBusy = false
        }
    }
    
    private func classify(image baseImage: MLImage?) -> CerealResult? {
        guard let mlImage = baseImage else {
            print("Failed to load Base iamge")
            return nil
        }
        
        do {
            let startDate = Date()
            let classificationResult = try classifier?.classify(mlImage: mlImage)
            let interval = Date().timeIntervalSince(startDate) * 1000
            let time = String(format: "%.2f", interval) + "s"
            let fieldData = displayStringsForResults(with: classificationResult)
            
            return CerealResult(inferenceTime: time, classificationLabel: fieldData.0, classificationScore: fieldData.1)
        } catch {
            print("Failed to classify cereal: \(error)")
            return nil
        }
    }
    
    private func displayStringsForResults(with result: ClassificationResult?) -> (String?, String?) {
        var fieldName: String? = nil
        var fieldScore: String? = nil
        
        guard let tempResult = result, let topResult = tempResult.classifications.first, topResult.categories.count > 0 else {
            return (fieldName, fieldScore)
        }
        
        let category = topResult.categories.first
        let percentScore = (category?.score ?? 0) * 100.0
        
        guard percentScore > minimumScore else {
            debugPrint("low confidence: \(percentScore)%")
            return (fieldName, fieldScore)
        }
        
        fieldName = category?.label?.convertSnakeToSentenceCase() ?? ""
        fieldScore = String(format: "%.2f", percentScore) + "%"
        
        return (fieldName, fieldScore)
    }
}
