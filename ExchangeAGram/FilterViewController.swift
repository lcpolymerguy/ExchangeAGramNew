//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Morgan Hart on 5/5/15.
//  Copyright (c) 2015 Morgan Hart. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var thisFeedItem: FeedItem!
    
    var collectionView: UICollectionView!
    
    let kIntensity = 0.7
    
    var context:CIContext = CIContext(options: nil)
    
    var filters:[CIFilter] = []
    
    let placeHolderImage = UIImage(named: "Placeholder")
    
    let tmp = NSTemporaryDirectory()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        // Register our FilterCell Class with the collection view, so that it knows which cell we will be using
        
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    // UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    // Update our cellForItemAtIndexPath function so that we can setup the dequeueReusableCellWithIdentifier function
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
         
        cell.imageView.image = placeHolderImage
        
        let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        
        dispatch_async(filterQueue, { () -> Void in
            
            // let filterImage = self.filteredImageFromImage(self.thisFeedItem.thumbNail, filter: self.filters[indexPath.row])
            
            let filterImage = self.getCachedImage(indexPath.row)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
            })
        })
        
        return cell
    }

    // UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbNail = thumbNailData
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Helper functions
    
    func photoFilters () -> [CIFilter] {
        
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
        
    }
   
    // Now that we have all our filters ready, we need to figure out how to save a chosen filter to our selected image. For this we will create a helper function that will take our imageData and a CIFilter instance, and return a new UIImage
    
    func filteredImageFromImage (imageData: NSData, filter:CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage:CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage)
        
        // let finalImage = UIImage(CIImage: filteredImage)
        
        return finalImage!
        
    }
    
    // caching functions
    
    func cacheImage(imageNumber: Int) {
        
        let fileName = "\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            
            let data = self.thisFeedItem.thumbNail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }
    
    func getCachedImage (imageNumber: Int) -> UIImage {
        
        let fileName = "\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        var image:UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            
            image = UIImage(contentsOfFile: uniquePath)!
        } else {
            
            self.cacheImage(imageNumber)
            image = UIImage(contentsOfFile: uniquePath)!
        }
        
        return image
    }
    
}
