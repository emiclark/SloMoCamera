//
//  Video.swift
//  SloMoCamera
//
//  Created by Emiko Clark on 4/19/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

import UIKit

class Video: NSObject, NSCoding {

    let videoPath : String
    let thumbnailPath : String
    let isSloMo : Bool
    let playbackRate : Float
    
    init(videoPath: String, thumbnailPath : String, isSloMo : Bool, playbackRate : Float) {
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.isSloMo = isSloMo
        self.playbackRate = playbackRate
        
    }
    
    
    // MARK: NSCoding methods
    
    public convenience required init?(coder decoder: NSCoder) {
        let videoPath = decoder.decodeObject(forKey: "videoPath") as! String
        let thumbnailPath = decoder.decodeObject(forKey: "thumbnailPath") as! String
        let isSloMo = decoder.decodeBool(forKey: "isSloMo")
        let playbackRate = decoder.decodeFloat(forKey: "playbackRate")
        
        self.init(videoPath: videoPath, thumbnailPath: thumbnailPath, isSloMo : isSloMo, playbackRate: Float(playbackRate))
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(videoPath, forKey: "videoPath")
        coder.encode(thumbnailPath, forKey: "thumbnailPath")
        coder.encode(isSloMo, forKey: "isSloMo")
        coder.encode(playbackRate, forKey: "playbackRate")
    }
    
    
}
