//
//  CameraManager.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import AVFoundation

final class CameraManager: ObservableObject {
    
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    static let shared = CameraManager()
    
    @Published var error: CameraError?
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.andresvi94.SessionQ")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var status = Status.unconfigured
    
    
    private init() {
        configure()
    }
    
    private func configure() {
        checkPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession()
            self.session.startRunning()
        }
    }
    
    func set(
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        queue: DispatchQueue
    ) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    
    private func configureCaptureSession() {
        guard status == .unconfigured else { return }
        
        defer {
            session.commitConfiguration()
        }
        
        session.beginConfiguration()
        
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let camera = device else {
            set(error: .cameraUnavailable)
            status = .failed
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(cameraInput) == true else {
                set(error: .cannotAddInput)
                status = .failed
                return
            }
            
            session.addInput(cameraInput)
            
        } catch {
            set(error: .createCaptureInput(error))
            status = .failed
            return
        }
        
        guard session.canAddOutput(videoOutput) == true else {
            set(error: .cannotAddOutput)
            status = .failed
            return
        }
        
        session.addOutput(videoOutput)
        
        videoOutput.videoSettings =
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        status = .configured
    }
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized {
                    self.status = .unauthorized
                    self.set(error: .deniedAuthorization)
                }
                self.sessionQueue.resume()
            }
        case .restricted:
            status = .unauthorized
            set(error: .restrictedAuthorization)
        case .denied:
            status = .unauthorized
            set(error: .deniedAuthorization)
        case .authorized:
            break
        @unknown default:
            status = .unauthorized
            set(error: .unknownAuthorization)
        }
    }
    
}
