//
//  VideoPlayerViewController.swift
//  SloMoCamera
//
//  Created by Emiko Clark on 5/1/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoPlayerViewController: UIViewController  {

    var video : Video?
//    var avplayer = AVQueuePlayer.init()
    var avplayer = AVPlayer()
    var avplayerLayer : AVPlayerLayer? = nil
    var previewLayer = AVCaptureVideoPreviewLayer()
    let myRate : Float = 0.0125
    let invisiblePlayButton =  UIButton()
    let doneButton = UIButton()
    var playerIsPlaying = false
    var playerItem : AVPlayerItem?
    
    // MARK: View Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .black

        //get url of track
//        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending((self.video?.videoPath)!)
//        let url = NSURL(fileURLWithPath: (path)!)
        
//        print("VideoPlayerViewController >>>>>>  VideoPlayerURL: \(url)\n\n")

//        //set up avplayer, clear current queue if playing straight away
//        self.avplayer.removeAllItems()
//        
//        var error:NSError?        
//        if (url.checkResourceIsReachableAndReturnError(&error) == false) {
//
//            self.playerItem = AVPlayerItem(url: url as URL)
//            self.avplayer.insert(playerItem!, after: nil)
//            
//            avplayerLayer = AVPlayerLayer(player: self.avplayer)
//            view.layer.insertSublayer(avplayerLayer!, at: 0)
//
////            self.avplayer.replaceCurrentItem(with: playerItem)
//            self.avplayer.pause()
//
//        }
        
        
        avplayerLayer = AVPlayerLayer(player: avplayer)
        view.layer.insertSublayer(avplayerLayer!, at: 0)
        
////        playerItem = AVPlayerItem(url: url as URL)
////        avplayer.replaceCurrentItem(with: playerItem)
        
        
        
        
        // create play button
        view.addSubview(invisiblePlayButton)
        invisiblePlayButton.setTitle("Play", for: .normal)
        invisiblePlayButton.frame = CGRect(x: 100, y: 200, width: 100, height: 60)
        invisiblePlayButton.center = view.center
        invisiblePlayButton.titleLabel?.font = UIFont(name: "Helvetica Bold", size: 30)
        invisiblePlayButton.tintColor = .white
        invisiblePlayButton.addTarget(self, action: #selector(invisibleButtonTapped), for: .touchUpInside)
        
        // add done button to dismiss playerVC
        doneButton.setTitle("Done", for: .normal)
        doneButton.frame = CGRect(x: 20, y: 30, width: 75, height: 40)
        doneButton.titleLabel?.font = UIFont(name: "Helvetica", size: 20)
        doneButton.backgroundColor = .blue
        doneButton.backgroundColor?.withAlphaComponent(0.5)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        view.addSubview(doneButton)
        view.bringSubview(toFront: doneButton)

        // add observer to check when video finished playing
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        setVideoOrientation()
        avplayer.rate = (video?.playbackRate)!
        print("playbackRate: \(String(describing: avplayer.rate))")
        invisiblePlayButton.isHidden = false
        avplayer.pause()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        avplayerLayer?.frame = view.bounds
        invisiblePlayButton.frame = view.bounds
    }

    
    func playerDidFinishPlaying(note: NSNotification) {
        // reset params
        playerIsPlaying = true
        invisiblePlayButton.isHidden = false
    }
    
    
    func setVideoOrientation() {
        // sets the video orientation of prevew layer
        if let connection = self.previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
                self.previewLayer.frame = self.view.bounds
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func invisibleButtonTapped(sender: UIButton) {
    
        // begin playing
        avplayer.seek(to: kCMTimeZero)
        invisiblePlayButton.isHidden = true
        print("playbackRate: \(String(describing: avplayer.rate))")
        avplayer.playImmediately(atRate: (video?.playbackRate)!)
        
    }

    func doneButtonTapped(sender: UIButton) {
        print("Done Tapped")
        dismiss(animated: true, completion: nil)
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
