//
//  FlickrPhotosViewController.swift
//  FlickrSearch
//
//  Created by Richard Turton on 13/04/2015.
//  Copyright (c) 2015 Richard turton. All rights reserved.
//

import UIKit

class FlickrPhotosViewController: UICollectionViewController {
  
  private let reuseIdentifier = "FlickrCell"
  private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

  private var searches = [FlickrSearchResults]()
  private let flickr = Flickr()
  
  func photoForIndexPath(indexPath: NSIndexPath) -> FlickrPhoto {
    return searches[indexPath.section].searchResults[indexPath.row]
  }
  
  //1
  var largePhotoIndexPath : NSIndexPath? {
    didSet {
      //2
      var indexPaths = [NSIndexPath]()
      if largePhotoIndexPath != nil {
        indexPaths.append(largePhotoIndexPath!)
      }
      if oldValue != nil {
        indexPaths.append(oldValue!)
      }
      //3
      collectionView?.performBatchUpdates({
        self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
        return
        }){
          completed in
          //4
          if self.largePhotoIndexPath != nil {
            self.collectionView?.scrollToItemAtIndexPath(
              self.largePhotoIndexPath!,
              atScrollPosition: .CenteredVertically,
              animated: true)
          }
      }
    }
  }
  
  private var selectedPhotos = [FlickrPhoto]()
  private let shareTextLabel = UILabel()
  
  func updateSharedPhotoCount() {
    shareTextLabel.textColor = themeColor
    shareTextLabel.text = "\(selectedPhotos.count) photos selected"
    shareTextLabel.sizeToFit()
  }
  
  var sharing : Bool = false {
    didSet {
      collectionView?.allowsMultipleSelection = sharing
      collectionView?.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
      selectedPhotos.removeAll(keepCapacity: false)
      if sharing && largePhotoIndexPath != nil {
        largePhotoIndexPath = nil
      }
      
      let shareButton =
      self.navigationItem.rightBarButtonItems!.first!
      if sharing {
        updateSharedPhotoCount()
        let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
        navigationItem.setRightBarButtonItems([shareButton,sharingDetailItem], animated: true)
      }
      else {
        navigationItem.setRightBarButtonItems([shareButton], animated: true)
      }
    }
  }
  
  @IBAction func share(sender: AnyObject) {
    if searches.isEmpty {
      return
    }
    
    if !selectedPhotos.isEmpty {
      var imageArray = [UIImage]()
      for photo in self.selectedPhotos {
        imageArray.append(photo.thumbnail!);
      }
      
      let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil)
      let popover = UIPopoverController(contentViewController: shareScreen)
      popover.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItems!.first!,
        permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
    }
    sharing = !sharing
  }
}

// MARK: UICollectionViewDataSource
extension FlickrPhotosViewController {
  
  //1
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  //2
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  //3
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
      reuseIdentifier, forIndexPath: indexPath) as! FlickrPhotoCell
    let flickrPhoto = photoForIndexPath(indexPath)
    
    //1
    cell.activityIndicator.stopAnimating()
    
    //2
    if indexPath != largePhotoIndexPath {
      cell.imageView.image = flickrPhoto.thumbnail
      return cell
    }
    
    //3
    if flickrPhoto.largeImage != nil {
      cell.imageView.image = flickrPhoto.largeImage
      return cell
    }
    
    //4
    cell.imageView.image = flickrPhoto.thumbnail
    cell.activityIndicator.startAnimating()
    
    //5
    flickrPhoto.loadLargeImage {
      loadedFlickrPhoto, error in
      
      //6
      cell.activityIndicator.stopAnimating()
      
      //7
      if error != nil {
        return
      }
      
      if loadedFlickrPhoto.largeImage == nil {
        return
      }
      
      //8
      if indexPath == self.largePhotoIndexPath {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrPhotoCell {
          cell.imageView.image = loadedFlickrPhoto.largeImage
        }
      }
    }
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
      //1
      switch kind {
        //2
      case UICollectionElementKindSectionHeader:
        //3
        let headerView =
        collectionView.dequeueReusableSupplementaryViewOfKind(kind,
          withReuseIdentifier: "FlickrPhotoHeaderView",
          forIndexPath: indexPath)
          as! FlickrPhotoHeaderView
        headerView.label.text = searches[indexPath.section].searchTerm
        return headerView
      default:
        //4
        assert(false, "Unexpected element kind")
      }
  }

}

// MARK: UICollectionViewDelegate
extension FlickrPhotosViewController {
  
  override func collectionView(collectionView: UICollectionView,
    shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
      
      if sharing {
        return true
      }
      
      if largePhotoIndexPath == indexPath {
        largePhotoIndexPath = nil
      }
      else {
        largePhotoIndexPath = indexPath
      }
      return false
  }
  
  override func collectionView(collectionView: UICollectionView,
    didSelectItemAtIndexPath indexPath: NSIndexPath) {
      if sharing {
        let photo = photoForIndexPath(indexPath)
        selectedPhotos.append(photo)
        updateSharedPhotoCount()
      }
  }
  
}

extension FlickrPhotosViewController : UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    // 1
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    textField.addSubview(activityIndicator)
    activityIndicator.frame = textField.bounds
    activityIndicator.startAnimating()
    flickr.searchFlickrForTerm(textField.text!) {
      results, error in
      
      //2
      activityIndicator.removeFromSuperview()
      if error != nil {
        print("Error searching : \(error)")
      }
      
      if results != nil {
        //3
        print("Found \(results!.searchResults.count) matching \(results!.searchTerm)")
        self.searches.insert(results!, atIndex: 0)
        
        //4
        self.collectionView?.reloadData()
      }
    }
    
    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
}

extension FlickrPhotosViewController : UICollectionViewDelegateFlowLayout {
  //1
  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      
      let flickrPhoto = photoForIndexPath(indexPath)
      
      // New code
      if indexPath == largePhotoIndexPath {
        var size = collectionView.bounds.size
        size.height -= topLayoutGuide.length
        size.height -= (sectionInsets.top + sectionInsets.right)
        size.width -= (sectionInsets.left + sectionInsets.right)
        return flickrPhoto.sizeToFillWidthOfSize(size)
      }
      // Previous code
      if var size = flickrPhoto.thumbnail?.size {
        size.width += 10
        size.height += 10
        return size
      }
      return CGSize(width: 100, height: 100)
  }
  
  //3
  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAtIndex section: Int) -> UIEdgeInsets {
      return sectionInsets
  }
}
