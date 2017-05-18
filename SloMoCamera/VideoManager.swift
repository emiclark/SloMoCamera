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
    var playbackRate : Float = 1.0
    
    var VideoObjectsArray = [Video]()
    
    // MARK: Init Method

    private override init() {
        
    }
    
    
    // MARK: Helper Methods
    
    func initializeApp() {
        // loads existing videos from document directory into app
        
        // check if anything saved previously in documents directory
        if UserDefaults.standard.object(forKey: "VideoObjectsArray") != nil {
            // exists.

            // unarchive and set to VideoObjectArray
            let data = UserDefaults.standard.data(forKey: "VideoObjectsArray")
            if (NSKeyedUnarchiver.unarchiveObject(with: data!) as? [Video]) != nil {
                self.VideoObjectsArray = (NSKeyedUnarchiver.unarchiveObject(with: data!) as? [Video])!
                self.VideoObjectsArray.forEach({print($0.videoPath,$0.thumbnailPath, $0.playbackRate)})
            } else {
                print("There was an error")
            }
        }
        
            // get document directory path
            self.documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
            print(">>documentDirectoryPath", self.documentDirectoryPath!)
    }
    
    
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
    

    func saveMovie(movieURL : URL, playbackRate: Float) -> Video {
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
                let newVideo = Video.init(videoPath: moviePathString, thumbnailPath: thumbnailPathString!, playbackRate: Float(playbackRate))

                // add video Object to array
                self.VideoObjectsArray.append(newVideo)
                print(newVideo)
                
                // encode and archive VideoObjectsArray
                let encodedData = NSKeyedArchiver.archivedData(withRootObject: VideoObjectsArray)
                UserDefaults.standard.set(encodedData, forKey: "VideoObjectsArray")
                UserDefaults.standard.synchronize()
                
                return newVideo
                
                
            } catch {
                print("*** Error generating thumbnail: \(error.localizedDescription)")
            }
            
                
        } else {
            print("error saving file")
        }
        
        // return empty videoObject
        let video = Video.init(videoPath: "", thumbnailPath: "", playbackRate: 1.0)
        return video
    }    
}
