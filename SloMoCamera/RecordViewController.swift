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

    var VideoPlayerVC = VideoPlayerViewController()
    var avPlayer : AVPlayer?
    var DDMoviePathURL : URL?
    var movieWasSaved = false
    var newVideo : Video?
    var playbackRate : Float?
    
    let fps240PlaybackRate : Float = 0.125
    let fps120PlaybackRate : Float = 0.250
    let fps60PlaybackRate  : Float = 0.500
    
    @IBOutlet var previewView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordMode: UISegmentedControl!
    @IBOutlet weak var toggleButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var videoCaptureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
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
  
        newVideo = VideoManager.sharedInstance.saveMovie(movieURL: self.outputFileLocation!, playbackRate : Float(self.playbackRate!))
        
        // set properties in VideoPlayerVC
        let videoPlayerVC = VideoPlayerViewController()
        
        videoPlayerVC.video = newVideo
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        let filepath = documentDirectoryPath.appending((newVideo?.videoPath)!)
        let selectedVideoURL = URL(fileURLWithPath: (filepath))
        
        print("self.selectedVideoURL: \(String(describing: selectedVideoURL))")
    
        videoPlayerVC.video = newVideo
        videoPlayerVC.playerItem = AVPlayerItem(url: selectedVideoURL as URL)

        videoPlayerVC.avplayer = AVPlayer(playerItem: videoPlayerVC.playerItem)
        videoPlayerVC.avplayerLayer = AVPlayerLayer(player: videoPlayerVC.avplayer)
        view.layer.insertSublayer(videoPlayerVC.avplayerLayer!, at: 0)
        
        movieWasSaved = true
            
        // present view controller
        self.present(videoPlayerVC, animated: true)
        
        // present view controller
        self.present(self.VideoPlayerVC, animated: true)
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
            // check device supports 240/120/60 fps. if yes then set to highest supported frame rate
            if let formats = self.videoCaptureDevice?.formats as? [AVCaptureDeviceFormat] {
                for format in formats {
                    
                    for range in (format.videoSupportedFrameRateRanges as? [AVFrameRateRange])! {
                        
                        // check for valid slow motion frame rates - 240/120/60 FPS
                        if (range.maxFrameRate == 240
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 240fps
                                isFPSSupported = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                self.playbackRate = fps240PlaybackRate
                                activeFormat = format
                                break
                        } else if (range.maxFrameRate == 120
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 120fps
                                isFPSSupported = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                self.playbackRate = 0.25
                                activeFormat = format
                                break
                        } else if (range.maxFrameRate == 60
                            && range.maxFrameRate >= Double(desiredFrameRate)
                            && range.minFrameRate <= Double(desiredFrameRate)) {
                                // supports 60fps
                                isFPSSupported = true
                                desiredFrameRate = Int32(range.maxFrameRate)
                                self.playbackRate = Float(range.maxFrameRate)
                                activeFormat = format
                                self.playbackRate = 0.5
                                break
                        }
                        
                        print(range)
                    }
                }
            }
            
            if self.recordMode.selectedSegmentIndex == 0 {
                // normal 30fps recording with playback at normal rate
                playbackRate = 1.0
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


