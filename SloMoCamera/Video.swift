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
    
    init(videoPath: String, thumbnailPath : String, isSloMo : Bool) {
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.isSloMo = isSloMo
        
    }
    
    
    // MARK: NSCoding methods
    
    public convenience required init?(coder decoder: NSCoder) {
        let videoPath = decoder.decodeObject(forKey: "videoPath") as! String
        let thumbnailPath = decoder.decodeObject(forKey: "thumbnailPath") as! String
        let isSloMo = decoder.decodeBool(forKey: "isSloMo")
        
        self.init(videoPath: videoPath, thumbnailPath: thumbnailPath, isSloMo : isSloMo)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(videoPath, forKey: "videoPath")
        coder.encode(thumbnailPath, forKey: "thumbnailPath")
        coder.encode(isSloMo, forKey: "isSloMo")
    }
    
    
}
