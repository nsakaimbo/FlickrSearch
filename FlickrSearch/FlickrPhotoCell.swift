//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by Richard Turton on 13/04/2015.
//  Copyright (c) 2015 Richard turton. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.isSelected = false
  }
  
  override var isSelected : Bool {
    didSet {
      self.backgroundColor = isSelected ? themeColor : UIColor.black()
    }
  }
}
