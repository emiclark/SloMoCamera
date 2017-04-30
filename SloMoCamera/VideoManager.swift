//
//  VideoManager.swift
//  SloMoCamera
//
//  Created by Emiko Clark on 4/17/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

import UIKit
import CoreMedia
import AVKit
import AVFoundation


class VideoManager: NSObject {

    
    // MARK: Properties
    
    static let sharedInstance = VideoManager()

    var dateString : String?
    var DDfilePathString :String?
    var documentDirectoryPath : String?
    var videoObjectArrayPath : String?
//    var isSloMo : Bool?

    var VideoObjectsArray = [Video]()
    
    private override init() {
        
    }
    
    
    // MARK: Helper
    
    func getNewPath(forFilename: String) -> String {
        // create timestamp filename for asset to be saved to document directory
        // eg: 041517-021155-video.mov & 041517-021155-thumbnail.jpg
        let newDate = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "/MMddyy-hhmmss-"
        self.dateString = formatter.string(from: newDate)
        let pathname = self.dateString?.appending(forFilename)
        print("pathname:>> \(String(describing: pathname))")
        return pathname!

    }
    
    func saveMovie(movieURL : URL, isSloMo : Bool) {
        // save video, thumbnail and videoObjectsArray to documents directory
        
        // set new video pathname
        let moviePathString = getNewPath(forFilename: "video.mp4")
        let moviePath = self.documentDirectoryPath?.appending(moviePathString)
        
        if let urlData = NSData(contentsOf: movieURL) {
            
            if let isSuccess = try? urlData.write(to: URL(fileURLWithPath: moviePath!)) {
                print("Success saving video", isSuccess)
            } else {
                print("write video file failed")
            }

            // generate thumbnail for video. If successful, save object to videoArray
            do {
                let asset = AVURLAsset(url: movieURL, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                
                // set new thumbnail pathname
                let thumbnailPathString = self.dateString?.appending("thumbnail.png")
                
                // write thumbnail to Documents Directory
                let thumbnail = UIImage(cgImage: cgImage)
                if let data = UIImagePNGRepresentation(thumbnail) {
                    let thumbnailPath = self.documentDirectoryPath?.appending(thumbnailPathString!)
                    try? data.write(to: URL(fileURLWithPath: thumbnailPath!))
                }
                
                // add new video & thumbnail object to videoArray
                let newVideo = Video.init(videoPath: moviePathString, thumbnailPath: thumbnailPathString!, isSloMo : isSloMo)
                
                // add video Object to array
                self.VideoObjectsArray.append(newVideo)
                
                
                
            } catch {
                print("*** Error generating thumbnail: \(error.localizedDescription)")
            }
            
            // encode and archive VideoObjectsArray to documents directory
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.VideoObjectsArray, toFile: self.videoObjectArrayPath!)
            
                if !isSuccessfulSave {
                print("Failed to save video and data.")
            }
                
        } else {
            print("error saving file")
        }
    }
    
    
    func initializeApp() {
        // loads existing videos from document directory into app
        
        // get path for documents directory
        self.documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        self.videoObjectArrayPath = self.documentDirectoryPath?.appending("/VideoObjectsArray")
        print(self.videoObjectArrayPath!)
        let url = URL(fileURLWithPath: self.videoObjectArrayPath!)
        
        // if file exists then unarchive
        guard let result = NSData(contentsOf: url)
            else {
            // No data in your fileURL. So no data is received. Do your task if you got no data
            // Keep in mind that you don't have access to your result here.
            // You can return from here.
            return
        }
        // You got your data successfully that was in your fileURL location. Do your task with your result.
        // You can have access to your result variable here. You can do further with result constant.
        let result1 = NSKeyedUnarchiver.unarchiveObject(with: result as Data)
        self.VideoObjectsArray = result1 as! [Video]
        
    }
    
    
//    func configureCameraFPS(videoDevice : AVCaptureDevice,  desiredFrameRate: Float64)  {
//        var isFPSSupported = false
//        let cameraSupportedRanges = videoDevice.activeFormat
//        
//        for format in (videoDevice.formats)! {
//            for range in (format as AnyObject).videoSupportedFrameRateRanges {
//                if (desiredFrameRate <= (range as AnyObject).maxFrameRate && desiredFrameRate >= (range as AnyObject).minFrameRate){
//                    // set desired frame rate
//                    isFPSSupported = true
//                }
//            }
//        
//            if isFPSSupported {
//                videoDevice.lockForConfiguration {
//                videoDevice.activeVideoMaxFrameDuration = CMTimeMake( 1, Int32(desiredFrameRate) )
//                videoDevice.activeVideoMinFrameDuration = CMTimeMake( 1, Int32(desiredFrameRate) )
//                videoDevice.unlockForConfiguration
//            } else {
//                print("error")
//            }
//        }
//    }
    


//    func attemptToConfigure5FPS(videoDevice : AVCaptureDevice,  desiredFrameRate: Int) {
//        let error : NSError?
//
//        
//        if (videoDevice.lockForConfiguration) {
//                print("Could not lock device %@ for configuration: \(self), \(error)")
//            
//            let format = videoDevice.activeFormat
//            let epsilon = 0.00000001
//            let desiredFrameRate = 120
//            
//            for ( range in format.videoSupportedFrameRateRanges) {
//                
//                if (range.minFrameRate <= (desiredFrameRate + epsilon) &&
//                    range.maxFrameRate >= (desiredFrameRate - epsilon)) {
//                    
//                    self.activeVideoMaxFrameDuration = (CMTime){
//                        .value = 1,
//                        .timescale = desiredFrameRate,
//                        .flags = kCMTimeFlags_Valid,
//                        .epoch = 0,
//                    }
//                    self.activeVideoMinFrameDuration = (CMTime){
//                        .value = 1,
//                        .timescale = desiredFrameRate,
//                        .flags = kCMTimeFlags_Valid,
//                        .epoch = 0,
//                    }
//                    break
//                }
//            }
//            
//            videoDevice.unlockForConfiguration()
//
//        } catch {
//            print(error?.localizedDescription)
//        }
//        
//        
//            }


    
}


