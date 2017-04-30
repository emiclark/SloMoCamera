//
//  RecordViewController.swift
//  SloMoCamera
//
//  Created by Emiko Clark on 4/14/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import AVKit
import Photos


class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    var avPlayerViewController = AVPlayerViewController()
    var avPlayer : AVPlayer?
    var DDMoviePathURL : URL?
    var isSloMo = false
    var movieWasSaved = false
    var newVideo : Video?
    
    @IBOutlet var previewView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordMode: UISegmentedControl!
    @IBOutlet weak var toggleButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var videoCaptureDevice : AVCaptureDevice?
    var previewLayer :AVCaptureVideoPreviewLayer?
    var movieFileOutput = AVCaptureMovieFileOutput()
    let MAX_RECORDED_DURATION = Int64(10.0) // max seconds to record video
    
    var outputFileLocation : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VideoManager.sharedInstance.initializeApp()
        self.initializeCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        self.setVideoOrientation()
    }
    
    

    // MARK: Button Actions
    

    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
        
        print("saved outputFileLocation: ->>", self.outputFileLocation!)
        
        if (self.outputFileLocation != nil) {
            
            // save recorded video to device
            VideoManager.sharedInstance.saveMovie(movieURL: self.outputFileLocation!, isSloMo: self.isSloMo)
            movieWasSaved = true
            
            // set up player VC
            if let url = self.outputFileLocation {
                
                self.avPlayer = AVPlayer(url: url)
                
                if self.isSloMo == true {
                    // playback at 1/2 speed
                    print(self.isSloMo)
                    self.avPlayer?.rate = 0.125
                } else {
                    // playback at regular speed
                    print(self.isSloMo)
                    self.avPlayer?.rate = 1.0
                }
                
                self.avPlayerViewController.player = self.avPlayer
            }
            
            // present view controller
            self.present(self.avPlayerViewController, animated: true) { 
                self.avPlayerViewController.player?.play()

                // check if video was recorded in slo-mo
                if self.isSloMo == true {
                    // playback at 1/4 speed
                    print("playback in slomo- \(String(describing: self.avPlayer?.rate))")
//                    self.avPlayer?.setRate(0.02r5, time: CMTime(1,30))

//                    self.avPlayer?.rate = 0.025
                    self.avPlayer?.rate = 0.0625
                } else {
                    // playback at regular speed
                    print(self.isSloMo)
                    self.avPlayer?.rate = 1.0
                }
                
            }
        }
        self.captureSession.startRunning()
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        
        // record video
        
        if recordButton.currentTitle == "Record" {
            
            //  let inp = self.captureSession.inputs[0]
            
            self.captureSession.startRunning()

            // get camera orientation
            self.movieFileOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = self.videoOrientation()
            self.movieFileOutput.maxRecordedDuration = self.maxRecordedDuration()
            
            // write to file location
            self.movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: self.videoFileLocation()), recordingDelegate: self)
            self.updateRecordButtonTitle()

        } else {
            // restart capture session if record button tapped again before save button
            self.captureSession.stopRunning()
            self.updateRecordButtonTitle()
        }
    }

    
    @IBAction func recordModePressed(_ sender: UISegmentedControl) {
        // set capture mode to either normal:30fps or slow motion:60/120/240fps
        
        var isFPSSupported = false
        var activeFormat = AVCaptureDeviceFormat()
        var desiredFrameRate : Int32 = 30
        
        do {
            
            if let formats = self.videoCaptureDevice?.formats as? [AVCaptureDeviceFormat] {
                for format in formats {
                    
                    for range in (format.videoSupportedFrameRateRanges as? [AVFrameRateRange])! {
                        
                        // check for valid slow motion frame rates - 240/120/60 FPS
                        if (range.maxFrameRate == 240
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 240fps
                                isFPSSupported = true
                                isSloMo = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                activeFormat = format
                                break
                        } else if (range.maxFrameRate == 120
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 120fps
                                isFPSSupported = true
                                isSloMo = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                activeFormat = format
                                break
                        } else if (range.maxFrameRate == 60
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 60fps
                                isFPSSupported = true
                                isSloMo = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                activeFormat = format
                                break
                        }
                        
                        print(range)
                    }
                }
            }
            
            if isFPSSupported {
                try videoCaptureDevice?.lockForConfiguration()
                videoCaptureDevice?.activeFormat = activeFormat
                videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(Int64(1), Int32(desiredFrameRate))
                videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(Int64(1), Int32(desiredFrameRate))
                videoCaptureDevice?.unlockForConfiguration()
            }
            
        } catch {
            print("lockForConfiguration error: \(error.localizedDescription)")
        }
    }

        
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        // toggles between existing front and back camera
        self.switchCameraInput()
    }

    
    
    // MARK: Main
    
    func initializeCamera() {
        // finds and assign inputs and outputs on device for the video capture session
        
        // set video record quality to high
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        // get video camera information on device
        if #available(iOS 10.0, *) {
            let discovery = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified)
            
            // assign device from devices array if capture device has lens on back
            for device in (discovery?.devices)! as [AVCaptureDevice]{
                
                if device.hasMediaType(AVMediaTypeVideo) {
                    if device.position == AVCaptureDevicePosition.back {
                        self.videoCaptureDevice = device
                    }
                }
            }
            
        } else {
            // Fallback on earlier versions
            let discovery = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified)
            
            // assign device from devices array if capture device has lens on back
            for device in (discovery?.devices)! as [AVCaptureDevice]{
                
                if device.hasMediaType(AVMediaTypeVideo) {
                    if device.position == AVCaptureDevicePosition.back {
                        self.videoCaptureDevice = device
                    }
                }
            }
        }
        

        
        if videoCaptureDevice != nil {
            do {
                // add video as an input device
                try self.captureSession.addInput(AVCaptureDeviceInput(device: self.videoCaptureDevice))
                
                // check default audio inputs on device and add them as input device
//                if let audioInput = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) {
//                    try self.captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
//                }
                
                // create preview layer to view recording scene
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                
                // set size to device screen
                self.previewView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                // add subview
                self.previewView.layer.addSublayer(self.previewLayer!)
                
                // set camera orientation
                self.setVideoOrientation()
                
                // add output file
                self.captureSession.addOutput(self.movieFileOutput)
                
                // begin capture session
                self.captureSession.startRunning()
                
            } catch {
                print(error)
            }
        }
        
    }
    
    func setVideoOrientation() {
        // sets the video orientation of prevew layer
        if let connection = self.previewLayer?.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = self.videoOrientation()
                self.previewLayer?.frame = self.view.bounds
            }
        }
    }
    
    
    func switchCameraInput () {
        // toggles between the front and back cameras on device 
        
        // unlock the session to make changes
        self.captureSession.beginConfiguration()
        
        // query device for front and back camera to allow toggling betweeen them
        var existingConnection : AVCaptureDeviceInput!
        
        for connection in self.captureSession.inputs {
            let input = connection as! AVCaptureDeviceInput
            if input.device.hasMediaType(AVMediaTypeVideo) {
                existingConnection = input
            }
        }
        
        // remove current input connection from the session
        self.captureSession.removeInput(existingConnection)
        
        // create new input connection
        var newCamera : AVCaptureDevice!
        
        // check position of old device and set the newCamera to the opposite
        if let oldCamera = existingConnection {
            if oldCamera.device.position == .back {
                if #available(iOS 10.0, *) {
                    newCamera = self.cameraWithPosition(position: .front)
                } else {
                    // Fallback on earlier versions
                }
            } else {
                if #available(iOS 10.0, *) {
                    newCamera = self.cameraWithPosition(position: .back)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        
        // get new input
        let newInput : AVCaptureDeviceInput!
        
        do {
            newInput = try AVCaptureDeviceInput(device: newCamera)
            self.captureSession.addInput(newInput)
        } catch {
            print(error)
        }
       
        self.captureSession.commitConfiguration()
    }
    
    
    // MARK: AVCaptureFileDelegate
    
    public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        // temp directory where video is saved to
        print("capture finished: --> \(outputFileURL)")
        self.outputFileLocation = outputFileURL
        self.captureSession.stopRunning()
    }
    
    // MARK: Helper Functions
    
    func videoOrientation () -> AVCaptureVideoOrientation {
        
        // returns the orientation of the camera
        var videoOrientation:AVCaptureVideoOrientation!
        
        let orientation : UIDeviceOrientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            videoOrientation = .portrait
        case .landscapeLeft:
            videoOrientation = .landscapeRight
        case .landscapeRight:
            videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        default:
            videoOrientation = .portrait
        }
        return videoOrientation
    }
    
    
    @available(iOS 10.0, *)
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        // queries if the device has video camera and returns valid camera position: front or back
        let discovery = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: position)
        
        for device in (discovery?.devices)! as [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        // camera does not have that camera position
        return nil
    }
    
    func videoFileLocation() -> String {
        // returns path for temp directory of recorded movie
        return NSTemporaryDirectory().appending("videoFile.mov")
    }
    
    func updateRecordButtonTitle() {
        
        // toggle record button title to Recording... when recording video
        if  self.captureSession.isRunning {
            self.recordButton.setTitle("Recording..", for: .normal)
        }
        else {
            self.recordButton.setTitle("Record", for: .normal)
        }
    }
    
    func maxRecordedDuration() -> CMTime {
        // maximum length of video that can be recorded
        let seconds :Int64 = MAX_RECORDED_DURATION
        let preferredTime :Int32 = 1
        return CMTimeMake(seconds, preferredTime)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



//========
//@IBAction func recordModePressed(_ sender: UISegmentedControl) {
//    // set the capture mode to either normal:30fps or slow motion:60fps
//    
//    var selectedFormat : AVCaptureDeviceFormat?
//    
//    // query the valid fps range for device
//    for format in (self.videoCaptureDevice?.formats)! {
//        for range in (format as AnyObject).videoSupportedFrameRateRanges {
//            if #available(iOS 9.0, *) {
//                if 60 <= (range as AnyObject).maxFrameRate {
//                    selectedFormat = format as? AVCaptureDeviceFormat
//                }
//            }
//        }
//    }
//    
//    // video recording at 30fps selected
//    if self.recordMode.selectedSegmentIndex == 0 {
//        
//        // video recording at 30fps selected - normal
//        if format != nil {
//            
//            do {
//                try self.videoCaptureDevice?.lockForConfiguration()
//                self.videoCaptureDevice?.activeFormat = format
//
//                self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
//                self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
//                self.videoCaptureDevice?.unlockForConfiguration()
//                self.isSloMo = false
//            } catch {
//                print(error)
//            }
//        }
//    } else {
//        
//        // video recording at 120fps selected - slow motion
//        if selectedFormat != nil {
//
//            do {
//                try self.videoCaptureDevice?.lockForConfiguration()
//                self.videoCaptureDevice?.activeFormat = format
//                self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 120)
//                self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 120)
//                self.videoCaptureDevice?.unlockForConfiguration()
//                self.isSloMo = true
//            } catch {
//                print(error)
//            }
//
//        }
//    }
//}

//========================

////        var selectedFrameRate : Float64 = 60
////        let supportedFrameRates = self.videoCaptureDevice?.activeFormat.videoSupportedFrameRateRanges
////
////        // query the valid fps range for device
////        for framerate in supportedFrameRates! {
////
////            if #available(iOS 10.0, *) {
////                if ((framerate as AnyObject).maxFrameRate <= 120 || (framerate as AnyObject).maxFrameRate <= 240) {
////                    selectedFrameRate = (framerate as AnyObject).maxFrameRate
////                }
////            }
////        }
//
//// video recording at 30fps selected
//if self.recordMode.selectedSegmentIndex == 0 {
//    
//    // video recording at 30fps selected - normal
//    //            if selectedFrameRate != nil {
//    
//    do {
//        self.captureSession.beginConfiguration()
//        try self.videoCaptureDevice?.lockForConfiguration()
//        //                    self.videoCaptureDevice?.activeFormat = Int32(selectedFrameRate!)
//        
//        self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, Int32(30))
//        self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
//        self.videoCaptureDevice?.unlockForConfiguration()
//        self.isSloMo = false
//        self.captureSession.commitConfiguration()
//    } catch {
//        print(error)
//    }
//    //            }
//} else {
//    
//    // video recording at 120fps or 240fps selected - slow motion
//    //            if (selectedFrameRate != nil && selectedFrameRate ==  240) {
//    
//    do {
//        self.captureSession.beginConfiguration()
//        try self.videoCaptureDevice?.lockForConfiguration()
//        //                    self.videoCaptureDevice?.activeFormat = selectedFrameRate
//        //                    self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(5, 1200)
//        //                    self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(5, Int32(1200))
//        self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 60)
//        self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 60)
//        self.videoCaptureDevice?.unlockForConfiguration()
//        self.captureSession.commitConfiguration()
//        self.isSloMo = true
//    } catch {
//        print(error)
//    }
//    
//    //            } else if (selectedFrameRate != nil && selectedFrameRate ==  120) {
//    //                // 240fps not available on device. set slo-mo speed to 120
//    //                do {
//    //                    self.captureSession.beginConfiguration()
//    //                    try self.videoCaptureDevice?.lockForConfiguration()
//    //                    //                    self.videoCaptureDevice?.activeFormat = selectedFrameRate
//    //                    self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(5, 600)
//    //                    self.videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(5, 600)
//    //                    self.videoCaptureDevice?.unlockForConfiguration()
//    //                    self.captureSession.commitConfiguration()
//    //                    self.isSloMo = true
//    //                } catch {
//    //                    print(error)
//    //                }
//    //            }
//}

//=================
//    func configureCameraFPS(desiredFrameRate: Float64)  {
//        var isFPSSupported = false
////        let cameraSupportedRanges = self.videoCaptureDevice?.activeFormat
//
//        for format in (self.videoCaptureDevice?.formats)! {
//            for range in (format as AnyObject).videoSupportedFrameRateRanges {
//                if (desiredFrameRate <= (range as AnyObject).maxFrameRate && desiredFrameRate >= (range as AnyObject).minFrameRate){
//                    // set desired frame rate
//                    isFPSSupported = true
//                }
//            }
//
//
//        }
//        if isFPSSupported {
//            do {
//
//
//                    self.captureSession.beginConfiguration()
//                    if self.videoCaptureDevice?.lockForConfiguration() {
//                        if 120 == self.videoCaptureDevice?.activeFormat.videoSupportedFrameRateRanges  {
//
//                        }
//
//                    } catch {
//                        print(error)
//                    }
//
//
//                [session beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
//                if ( [device lockForConfiguration:&error] ) {
//                    [device setActiveFormat:newFormat];
//                    [device setActiveVideoMinFrameDuration:newMinDuration];
//                    [device setActiveVideoMaxFrameDuration:newMaxDuration];
//                    [device unlockForConfiguration];
//
//
//
//
//
//
//
//
//                try self.videoCaptureDevice?.lockForConfiguration()
//                self.videoCaptureDevice?.activeFormat.videoSupportedFrameRateRanges = CMTimeMake( 1, Int32(desiredFrameRate) )
//                self.videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake( 1, Int32(desiredFrameRate) )
//                self.videoCaptureDevice?.unlockForConfiguration()
//
//            } catch {
//                print(error)
//            }
//        }
//    }


//====================================


//                    if (range.maxFrameRate >= Double(desiredFrameRate) && range.minFrameRate <= Double(desiredFrameRate)) {
//                        isFPSSupported = true
//                        try! videoCaptureDevice?.lockForConfiguration()
//                        videoCaptureDevice?.activeFormat = format
//                        videoCaptureDevice?.unlockForConfiguration()
//                        break
//                    }


//        var desiredFrameRate = CMTimeMake(1, 240);
//        var frameRateSupported = false
//        let deviceFrameRates  = AVFrameRateRange()
//        let supportedFrameRateRanges = videoCaptureDevice?.activeFormat
//
//        for  range in (supportedFrameRateRanges?.videoSupportedFrameRateRanges)! {
//
//            if desiredFrameRate >= (range as AnyObject).minFrameDuration && desiredFrameRate <= (range as AnyObject).maxFrameDuration {
//                frameRateSupported = true
//                print(desiredFrameRate)
//            }
//        }
//
////        let float = deviceFrameRates.maxFrameRate
////        print(float)
////
////        if  (deviceFrameRates.maxFrameRate == 240.0 ){
////            desiredFrameRate = CMTimeMake(1, 240)
////
////        } else if  ((desiredFrameRate.timescale != 240))  && (deviceFrameRates.maxFrameRate == 120) {
////            desiredFrameRate = CMTimeMake(1, 120)
////
////        }
////
//
////        if (frameRateSupported) {
//            do {
//                self.captureSession.beginConfiguration()
//                try videoCaptureDevice?.lockForConfiguration()
//                videoCaptureDevice?.activeVideoMinFrameDuration = desiredFrameRate
//                videoCaptureDevice?.activeVideoMaxFrameDuration = desiredFrameRate
//                videoCaptureDevice?.unlockForConfiguration()
//                self.captureSession.commitConfiguration()
//            } catch {
//                print(error)
//            }
//        }


//====================

//
//        func configureDevice() {
//
//            var bestFormat: AVCaptureDeviceFormat? = nil
////            var bestFrameRateRange: AVFrameRateRange? = nil
//            var bestFrameRateRange = CMTimeMake(1, <#T##timescale: Int32##Int32#>)
//
//            var bestPixelArea: Int32 = 0
//            for format in self.videoCaptureDevice!.formats {
//                let ranges = (format as AnyObject).videoSupportedFrameRateRanges as! [AVFrameRateRange];
//                for range in ranges {
//
//                    if bestFrameRateRange==nil || (range.maxFrameRate > bestFrameRateRange.maxFrameRate) || ((range.maxFrameRate == bestFrameRateRange.maxFrameRate)) {
//                        bestFormat = format as? AVCaptureDeviceFormat
//                        bestFrameRateRange = range
//                    }
//                }
//            }
//
//            do {
//
//                try self.videoCaptureDevice!.lockForConfiguration() {
//
//                    self.videoCaptureDevice!.activeFormat = bestFormat
//                    self.videoCaptureDevice!.activeVideoMinFrameDuration = bestFrameRateRange!.minFrameDuration
//                    self.videoCaptureDevice!.activeVideoMaxFrameDuration = bestFrameRateRange!.minFrameDuration
//
//                } catch { }
//
//                print(self.videoCaptureDevice!.activeFormat.videoSupportedFrameRateRanges)
//
//                self.videoCaptureDevice!.unlockForConfiguration()
//            }
//        }







//
//
//
//
//        // get supported frame rate for device
//
//        var deviceFrameRates = AVFrameRateRange()
//        var desiredFrameRate = CMTimeMake(1, 30)
//        var FPSSupported = false
//
//        let currentDeviceFormats = self.videoCaptureDevice?.activeFormat
//
//        for  range in (currentDeviceFormats?.videoSupportedFrameRateRanges)! {
////            if ( (range as! AVFrameRateRange).maxFrameRate >= desiredFrameRate && (range as! AVFrameRateRange).minFrameRate <= desiredFrameRate )        {
//
//            if ( ((range as! AVFrameRateRange).maxFrameRate >= desiredFrameRate.timescale) && ((range as! AVFrameRateRange).minFrameRate <= desiredFrameRate.timescale ))        {
//                FPSSupported = true
//            }
//
//
//            if  (deviceFrameRates.maxFrameRate == 240 ){
//                desiredFrameRate = CMTimeMake(1, 240)
//                print(range)
//                continue
//            } else if  ((desiredFrameRate.timescale != 240))  && (deviceFrameRates.maxFrameRate == 120) {
//                desiredFrameRate = CMTimeMake(1, 120)
//                print(desiredFrameRate)
//                continue
//
//            }
//            print(range)
//
//        }
//
//            self.captureSession.beginConfiguration()
//
//            do {
//                try self.videoCaptureDevice?.lockForConfiguration()
//
//                    self.videoCaptureDevice?.activeVideoMinFrameDuration = desiredFrameRate
//                    self.videoCaptureDevice?.activeVideoMaxFrameDuration = desiredFrameRate
//
//                    self.videoCaptureDevice?.unlockForConfiguration()
//                    print("begin Config: OK")
//                    self.isSloMo = true
//
//
//            } catch {
//                print("error")
//            }
//
//            self.captureSession.commitConfiguration()


//    }



//======================

//
//
//        if self.recordMode.selectedSegmentIndex == 0 {
//            // normal 30fps recording
//            if newFrameRates.maxFrameRate == 30 {
//
//                do {
//                    print(newFrameRates)
////                    try device.lockForConfiguration()
////                    device.activeFormat = vFormat as! AVCaptureDeviceFormat
////                    device.activeVideoMinFrameDuration = frameRates.minFrameDuration
////                    device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
////                    device.unlockForConfiguration()
//
//                } catch {
//                    print(error)
//                }
//            }
//
//        } else {
//            // slow motion 60/120/240fps recording
//            if frameRates.maxFrameRate == 240 || frameRates.maxFrameRate == 120 || frameRates.maxFrameRate == 60 {
//
//                do {
//                    try device.lockForConfiguration()
//                    device.activeFormat = vFormat as! AVCaptureDeviceFormat
//                    device.activeVideoMinFrameDuration = frameRates.minFrameDuration
//                    device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
//                    device.unlockForConfiguration()
//
//                } catch {
//                    print(error)
//                }
//            }
//
//        }



