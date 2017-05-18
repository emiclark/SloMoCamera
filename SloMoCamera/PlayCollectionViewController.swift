//
//  PlayCollectionViewController.swift
//  SloMoCamera
//
//  Created by Emiko Clark on 4/18/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

private let reuseIdentifier = "Cell"

class PlayCollectionViewController : UICollectionViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var thumbnail : UIImageView?
    let avPlayerViewController  = AVPlayerViewController()
    let videoManager = VideoManager.sharedInstance
    var avPlayer : AVPlayer? = nil
    var selectedVideoURL : URL? = nil
    var selectedVideo : Video?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }

    
    override func viewWillAppear(_ animated: Bool) {
        self.collectionView?.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return videoManager.VideoObjectsArray.count
    }

    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VideoCell

        let thumbPathStr =  videoManager.documentDirectoryPath?.appending(videoManager.VideoObjectsArray[indexPath.row].thumbnailPath)
        print("thumbPathStr: \(String(describing: thumbPathStr))")
        
        let thumbPath = URL(fileURLWithPath: thumbPathStr!)
        
        do {
            
            let thumbData = try Data.init(contentsOf: thumbPath)
            let thumbImage = UIImage(data: thumbData)
            cell.imageView.image = thumbImage
        } catch let error {
            print(error.localizedDescription)
        }
       
        return cell
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // set properties in VideoPlayerVC
        let videoPlayerVC = VideoPlayerViewController()
        
        // assign selected object to videoPlayerVC.video property
        videoPlayerVC.video = videoManager.VideoObjectsArray[indexPath.row]
        
        // find document directory path
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        let filepath = documentDirectoryPath.appending((videoPlayerVC.video?.videoPath)!)
        let selectedVideoURL = URL(fileURLWithPath: (filepath))
        videoPlayerVC.playerItem = AVPlayerItem(url: selectedVideoURL as URL)
        videoPlayerVC.avplayer = AVPlayer(playerItem: videoPlayerVC.playerItem)
        videoPlayerVC.avplayerLayer = AVPlayerLayer(player: videoPlayerVC.avplayer)
        view.layer.insertSublayer(videoPlayerVC.avplayerLayer!, at: 0)
        
        // present view controller
        self.present(videoPlayerVC, animated: true)

    }
    
    

    

    // Uncomment this method to specify if the specified item should be selected
//    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        return true
//    }

    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */

    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    // MARK: Misc
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
