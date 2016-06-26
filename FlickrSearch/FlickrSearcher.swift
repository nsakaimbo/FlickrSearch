//
//  FlickrSearcher.swift
//  flickrSearch
//
//  Created by Richard Turton on 31/07/2014.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import Foundation
import UIKit

let apiKey = APIKeys.flickr.key

struct FlickrSearchResults {
  let searchTerm : String
  let searchResults : [FlickrPhoto]
}

class FlickrPhoto : Equatable {
  var thumbnail : UIImage?
  var largeImage : UIImage?
  let photoID : String
  let farm : Int
  let server : String
  let secret : String
  
  init (photoID:String,farm:Int, server:String, secret:String) {
    self.photoID = photoID
    self.farm = farm
    self.server = server
    self.secret = secret
  }
  
  func flickrImageURL(_ size:String = "m") -> URL {
    return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")!
  }
  
  func loadLargeImage(_ completion: (flickrPhoto:FlickrPhoto, error: NSError?) -> Void) {
    let loadURL = flickrImageURL("b")
    let loadRequest = URLRequest(url:loadURL)
    NSURLConnection.sendAsynchronousRequest(loadRequest,
      queue: OperationQueue.main()) {
        response, data, error in
        
        if error != nil {
          completion(flickrPhoto: self, error: error)
          return
        }
        
        if data != nil {
          let returnedImage = UIImage(data: data!)
          self.largeImage = returnedImage
          completion(flickrPhoto: self, error: nil)
          return
        }
        
        completion(flickrPhoto: self, error: nil)
    }
  }
  
  func sizeToFillWidthOfSize(_ size:CGSize) -> CGSize {
    if thumbnail == nil {
      return size
    }
    
    let imageSize = thumbnail!.size
    var returnSize = size
    
    let aspectRatio = imageSize.width / imageSize.height
    
    returnSize.height = returnSize.width / aspectRatio
    
    if returnSize.height > size.height {
      returnSize.height = size.height
      returnSize.width = size.height * aspectRatio
    }
    
    return returnSize
  }
  
}

func == (lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
  return lhs.photoID == rhs.photoID
}

class Flickr {
  
  let processingQueue = OperationQueue()
    
    func searchFlickrForTerm(_ searchTerm: String, completion : (results: FlickrSearchResults?, error : NSError?) -> Void){
        
        guard let searchURL = flickrSearchURLForSearchTerm(searchTerm) else {
            print("Error. Invalid search string parameter.")
            return
        }
        
        let searchRequest = URLRequest(url: searchURL)
        
        NSURLConnection.sendAsynchronousRequest(searchRequest, queue: processingQueue) {response, data, error in
            
            if error != nil {
                completion(results: nil,error: error)
                return
            }
            
            let resultsDictionary: NSDictionary
            
            do {
                
                if let data = data {
                    
                    resultsDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! NSDictionary
                    
                    switch (resultsDictionary["stat"] as! String) {
                    case "ok":
                        print("Results processed OK")
                    case "fail":
                        let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:resultsDictionary["message"]!])
                        completion(results: nil, error: APIError)
                        return
                    default:
                        let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Uknown API response"])
                        completion(results: nil, error: APIError)
                        return
                    }
                    
                    let photosContainer = resultsDictionary["photos"] as! NSDictionary
                    let photosReceived = photosContainer["photo"] as! [NSDictionary]
                    
                    let flickrPhotos : [FlickrPhoto] = photosReceived.map {
                        photoDictionary in
                        
                        let photoID = photoDictionary["id"] as? String ?? ""
                        let farm = photoDictionary["farm"] as? Int ?? 0
                        let server = photoDictionary["server"] as? String ?? ""
                        let secret = photoDictionary["secret"] as? String ?? ""
                        
                        let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
                        
                        let imageData = try? Data(contentsOf: flickrPhoto.flickrImageURL())
                        flickrPhoto.thumbnail = UIImage(data: imageData!)
                        
                        return flickrPhoto
                    }
                    
                    DispatchQueue.main.async(execute: {
                        completion(results:FlickrSearchResults(searchTerm: searchTerm, searchResults: flickrPhotos), error: nil)
                    })
                }
            }
            catch {
                completion(results: nil, error: nil)
                fatalError("Error. Could not deserialize JSON result.")
            }
        }
    }
  
  private func flickrSearchURLForSearchTerm(_ searchTerm:String) -> URL? {
    
    guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
      return nil
    }
   
    let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
    return URL(string: URLString)
  }
    
}
