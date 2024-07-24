import AVFoundation
import UIKit

enum CameraControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

public enum CameraPosition {
    case front
    case rear
}

extension CameraControllerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .captureSessionAlreadyRunning:
            return NSLocalizedString("Capture Session is Already Running", comment: "Capture Session Already Running")
        case .captureSessionIsMissing:
            return NSLocalizedString("Capture Session is Missing", comment: "Capture Session Missing")
        case .inputsAreInvalid:
            return NSLocalizedString("Inputs Are Invalid", comment: "Inputs Are Invalid")
        case .invalidOperation:
            return NSLocalizedString("Invalid Operation", comment: "invalid Operation")
        case .noCamerasAvailable:
            return NSLocalizedString("Failed to access device camera(s)", comment: "No Cameras Available")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "Unknown")

        }
    }
}

class CameraController: NSObject {
    var captureSession: AVCaptureSession?
    
    var photoOutput = AVCapturePhotoOutput()
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    var sampleBufferCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var cameraInput: AVCaptureDeviceInput?
    
    var flashMode = AVCaptureDevice.FlashMode.off

    /** Video zoom factor that is used for manually zooming in and out via pinch gesture */
    var videoZoomFactor: CGFloat = 1

    public func prepare(cameraPosition: CameraPosition?, enableHighResolution isHighResolutionPhotoEnabled: Bool, completionHandler: @escaping (Error?) -> Void) {
        // Set up capture session
        let captureSession = AVCaptureSession()        
        self.captureSession = captureSession
        
        if (isHighResolutionPhotoEnabled) {
            captureSession.sessionPreset = .photo
        }
        
        // Set up preview layer
        previewLayer.session = captureSession
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                
        // Initialize front and back camera
        do {
            try initializeCameraDevices(forPosition: cameraPosition ?? .rear)
            try initializeCameraInput()
        } catch {
            completionHandler(error)
            return
        }
        
        // Adding the camera output might take quite some time so it's outsourced into a different queue
        // Configure camera output
        self.photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        self.photoOutput.isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        if captureSession.canAddOutput(self.photoOutput) {
            captureSession.addOutput(self.photoOutput)
        }
        
        captureSession.startRunning()
        
        // Lastly setting the video zoom factor
        do {
            try self.configureCameraSettings()
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
    
    public func stop() {
        self.captureSession?.stopRunning()
    }
    
    /**
     Initializes the available camera devices by selecting the best fit for the current iOS device.
     
     This method sets the current camera device to the requested one and also initializes the opposite camera for easy switching later.
     It configures virtual devices supporting ultra-wide angle and better autofocus to address several focus issues observed with newer iPhones.
     
     - Parameters:
     - cameraPosition: The position of the camera to initialize (front or rear).
     - Throws: `CameraControllerError.noCamerasAvailable` if no suitable camera is available.
     */
    private func initializeCameraDevices(forPosition cameraPosition: CameraPosition) throws {
        if let rearCamera = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            self.rearCamera = rearCamera
        } else {
            self.rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            self.frontCamera = frontCamera
        }
        
        guard cameraPosition == .rear && rearCamera != nil || cameraPosition == .front && frontCamera != nil else {
            throw CameraControllerError.noCamerasAvailable
        }
        
        self.currentCamera = cameraPosition == .rear ? rearCamera : frontCamera
    }
    
    /**
     Configure several camera related properties based on the currently selected camera device.
     This function also keeps care of the default zoom factor for the chosen camera device
     */
    private func configureCameraSettings() throws {
        guard let cameraDevice = self.currentCamera else {
            throw CameraControllerError.noCamerasAvailable;
        }

        try cameraDevice.lockForConfiguration()
        defer { cameraDevice.unlockForConfiguration() }
        
        if (cameraDevice.isFocusModeSupported(.continuousAutoFocus)) {
            cameraDevice.focusMode = .continuousAutoFocus
        }
        
        if (cameraDevice.isExposureModeSupported(.continuousAutoExposure)) {
            cameraDevice.exposureMode = .continuousAutoExposure
        }
        
        if (cameraDevice.deviceType == .builtInTripleCamera) {
            // Note that zoomFactor 2 "equals" the regular 1x zoom factor of the native iphone camera app
            // 0.5x however equal a videoZoomFactor of 1. We do not want to use ultra wide angle by default
            // the default videoZoomFactor to 2 in case the current camera device type is .builtInTripleCamera
            cameraDevice.videoZoomFactor = 2.0
        }
    }
    
    /**
     Initialize the camera inputs
     */
    private func initializeCameraInput() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        guard let camera = self.currentCamera else { throw CameraControllerError.noCamerasAvailable }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            self.cameraInput = cameraInput
        } catch {
            throw CameraControllerError.noCamerasAvailable
        }
    }
    
    public func displayPreview(on view: UIView) {
        view.layer.insertSublayer(self.previewLayer, at: 0)
        previewLayer.frame = view.frame
        updateVideoOrientation()
    }
    
    public func updateVideoOrientation() {
        assert(Thread.isMainThread)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        let interfaceOrientation = windowScene.interfaceOrientation

        let videoOrientation: AVCaptureVideoOrientation
        switch interfaceOrientation {
        case .portrait:
            videoOrientation = .portrait
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .unknown:
            videoOrientation = .portrait
        @unknown default:
            videoOrientation = .portrait
        }

        previewLayer.connection?.videoOrientation = videoOrientation
        photoOutput.connections.forEach { $0.videoOrientation = videoOrientation }
    }

    public func switchCameras() throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        guard let device = self.currentCamera else { throw CameraControllerError.noCamerasAvailable }

        captureSession.beginConfiguration()

        func switchToFrontCamera() throws {
            guard let cameraInput = self.cameraInput, captureSession.inputs.contains(cameraInput),
                  let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }

            captureSession.removeInput(cameraInput)
            
            let newCameraInput = try AVCaptureDeviceInput(device: frontCamera)

            if captureSession.canAddInput(newCameraInput) {
                captureSession.addInput(newCameraInput)
                self.cameraInput = newCameraInput
                self.currentCamera = frontCamera
            } else {
                throw CameraControllerError.invalidOperation
            }
        }

        func switchToRearCamera() throws {
            guard let cameraInput = self.cameraInput, captureSession.inputs.contains(cameraInput),
                  let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            
            captureSession.removeInput(cameraInput)
            
            let newCameraInput = try AVCaptureDeviceInput(device: rearCamera)

            if captureSession.canAddInput(newCameraInput) {
                captureSession.addInput(newCameraInput)
                self.cameraInput = newCameraInput
                self.currentCamera = rearCamera
            } else {
                throw CameraControllerError.invalidOperation
            }
        }

        switch device.position {
        case .front:
            try switchToRearCamera()
        case .back:
            try switchToFrontCamera()
        case .unspecified:
            return
        @unknown default:
            return
        }
        
        // Reconfigure camera settings
        try? self.configureCameraSettings()

        captureSession.commitConfiguration()
    }

    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else {
            completion(nil, CameraControllerError.captureSessionIsMissing);
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode

        self.photoOutput.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }

    func captureSample(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else {
            completion(nil, CameraControllerError.captureSessionIsMissing)
            return
        }

        self.sampleBufferCaptureCompletionBlock = completion
    }

    func getSupportedPictureSizes() -> [[String: Any]] {
        guard let device = self.currentCamera else { return [] }
        return device.activeFormat.supportedSizes.map { size in
            return [
                "width": size.width,
                "height": size.height
            ]
        }
    }

    func getExposureCompensation() -> Float {
        guard let device = self.currentCamera else { return 0 }
        return device.exposureTargetBias
    }

    func getExposureCompensationRange() -> [Float] {
        guard let device = self.currentCamera else { return [0, 0] }
        return [device.minExposureTargetBias, device.maxExposureTargetBias]
    }

    func getExposureMode() -> String {
        guard let device = self.currentCamera else { return "unknown" }
        return device.exposureMode.rawValue
    }

    func getWhiteBalanceMode() -> String {
        guard let device = self.currentCamera else { return "unknown" }
        return device.whiteBalanceMode.rawValue
    }

    func getSupportedWhiteBalanceModes() -> [String] {
        guard let device = self.currentCamera else { return [] }
        return device.supportedWhiteBalanceModes.map { $0.rawValue }
    }


    func getSupportedFlashModes() throws -> [String] {
        guard let device = self.currentCamera else { throw CameraControllerError.noCamerasAvailable }

        var supportedFlashModesAsStrings: [String] = []
        if device.hasFlash {
            for flashMode in self.photoOutput.supportedFlashModes {
                var flashModeValue: String?
                
                switch flashMode {
                case AVCaptureDevice.FlashMode.off:
                    flashModeValue = "off"
                case AVCaptureDevice.FlashMode.on:
                    flashModeValue = "on"
                case AVCaptureDevice.FlashMode.auto:
                    flashModeValue = "auto"
                default: break
                }
                
                if flashModeValue != nil {
                    supportedFlashModesAsStrings.append(flashModeValue!)
                }
            }
        }
        
        if device.hasTorch {
            supportedFlashModesAsStrings.append("torch")
        }
        
        return supportedFlashModesAsStrings
    }

    func setFlashMode(flashMode: AVCaptureDevice.FlashMode) throws {
        guard let device = self.currentCamera else { throw CameraControllerError.noCamerasAvailable }
        
        if !self.photoOutput.supportedFlashModes.contains(flashMode) {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if device.hasTorch && device.isTorchAvailable && device.torchMode == AVCaptureDevice.TorchMode.on {
                device.torchMode = AVCaptureDevice.TorchMode.off
            }
            
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = flashMode
            
            self.flashMode = flashMode
            self.photoOutput.photoSettingsForSceneMonitoring = photoSettings
            
            device.unlockForConfiguration()
        } catch {
            throw CameraControllerError.invalidOperation
        }
    }

    func setTorchMode() throws {
        guard let device = self.currentCamera, device.hasTorch, device.isTorchAvailable else {
            throw CameraControllerError.invalidOperation
        }

        do {
            try device.lockForConfiguration()
            
            if device.isTorchModeSupported(AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.on
            } else if device.isTorchModeSupported(AVCaptureDevice.TorchMode.auto) {
                device.torchMode = AVCaptureDevice.TorchMode.auto
            } else {
                device.torchMode = AVCaptureDevice.TorchMode.off
            }
            
            device.unlockForConfiguration()
        } catch {
            throw CameraControllerError.invalidOperation
        }
    }
    
    public func setupGestures(target: UIView, enableZoom: Bool) {
        setupTapGesture(target: target, selector: #selector(handleTap(_:)), delegate: self)
        if enableZoom {
            setupPinchGesture(target: target, selector: #selector(handlePinch(_:)), delegate: self)
        }
    }

    private func setupTapGesture(target: UIView, selector: Selector, delegate: UIGestureRecognizerDelegate?) {
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        tapGesture.delegate = delegate
        target.addGestureRecognizer(tapGesture)
    }

    private func setupPinchGesture(target: UIView, selector: Selector, delegate: UIGestureRecognizerDelegate?) {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: selector)
        pinchGesture.delegate = delegate
        target.addGestureRecognizer(pinchGesture)
    }
    
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error = error {
            self.photoCaptureCompletionBlock?(nil, error)
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
            return
        }
        
        self.photoCaptureCompletionBlock?(image.fixedOrientation(), nil)
    }
}

extension CameraController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func handleTap(_ tap: UITapGestureRecognizer) {
        guard let device = self.currentCamera else { return }

        let point = tap.location(in: tap.view)
        let devicePoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                device.focusPointOfInterest = CGPoint(x: CGFloat(devicePoint.x), y: CGFloat(devicePoint.y))
                device.focusMode = focusMode
            }

            let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                device.exposurePointOfInterest = CGPoint(x: CGFloat(devicePoint.x), y: CGFloat(devicePoint.y))
                device.exposureMode = exposureMode
            }
        } catch {
            debugPrint(error)
        }
    }

    @objc private func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        guard let device = self.currentCamera else { return }

        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
        }

        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                device.videoZoomFactor = factor
            } catch {
                debugPrint(error)
            }
        }

        switch pinch.state {
        case .began: fallthrough
        case .changed:
            let newScaleFactor = minMaxZoom(pinch.scale)
            update(scale: newScaleFactor)
        case .ended:
            videoZoomFactor = device.videoZoomFactor
        default: break
        }
    }
}
