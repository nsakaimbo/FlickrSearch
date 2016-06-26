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
  
  func photoForIndexPath(_ indexPath: IndexPath) -> FlickrPhoto {
    return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as NSIndexPath).row]
  }
  
  //1
  var largePhotoIndexPath : IndexPath? {
    didSet {
      //2
      var indexPaths = [IndexPath]()
      if largePhotoIndexPath != nil {
        indexPaths.append(largePhotoIndexPath!)
      }
      if oldValue != nil {
        indexPaths.append(oldValue!)
      }
      //3
      collectionView?.performBatchUpdates({
        self.collectionView?.reloadItems(at: indexPaths)
        return
        }){
          completed in
          //4
          if self.largePhotoIndexPath != nil {
            self.collectionView?.scrollToItem(
              at: self.largePhotoIndexPath!,
              at: .centeredVertically,
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
      collectionView?.selectItem(at: nil, animated: true, scrollPosition: UICollectionViewScrollPosition())
      selectedPhotos.removeAll(keepingCapacity: false)
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
  
  @IBAction func share(_ sender: AnyObject) {
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
      popover.present(from: self.navigationItem.rightBarButtonItems!.first!,
        permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
    }
    sharing = !sharing
  }
}

// MARK: UICollectionViewDataSource
extension FlickrPhotosViewController {
  
  //1
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  //2
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  //3
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
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
        if let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell {
          cell.imageView.image = loadedFlickrPhoto.largeImage
        }
      }
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath) -> UICollectionReusableView {
      //1
      switch kind {
        //2
      case UICollectionElementKindSectionHeader:
        //3
        let headerView =
        collectionView.dequeueReusableSupplementaryView(ofKind: kind,
          withReuseIdentifier: "FlickrPhotoHeaderView",
          for: indexPath)
          as! FlickrPhotoHeaderView
        headerView.label.text = searches[(indexPath as NSIndexPath).section].searchTerm
        return headerView
      default:
        //4
        assert(false, "Unexpected element kind")
      }
  }

}

// MARK: UICollectionViewDelegate
extension FlickrPhotosViewController {
  
  override func collectionView(_ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath) -> Bool {
      
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
  
  override func collectionView(_ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath) {
      if sharing {
        let photo = photoForIndexPath(indexPath)
        selectedPhotos.append(photo)
        updateSharedPhotoCount()
      }
  }
  
}

extension FlickrPhotosViewController : UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // 1
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
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
        self.searches.insert(results!, at: 0)
        
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
  func collectionView(_ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize {
      
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
  func collectionView(_ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int) -> UIEdgeInsets {
      return sectionInsets
  }
}
