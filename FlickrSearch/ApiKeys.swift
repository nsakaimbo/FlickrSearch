//
//  APIKeys.swift
//  FlickrSearch
//
//  Created by Nicholas Sakaimbo on 6/12/16.
//  Copyright © 2016 Richard turton. All rights reserved.
//

import Foundation

enum APIKeys {
    
    case Flickr
    
    private var name: String {
        switch self {
        case .Flickr: return "FlickrAPIKey"
        }
    }
    
    var key: String {
       
        let keyname = self.name
        
        guard let filePath = NSBundle.mainBundle().pathForResource("ApiKeys", ofType:"plist"),
            plist = NSDictionary(contentsOfFile:filePath),
            apiKey = plist.objectForKey(keyname) as? String else {
                
                fatalError("Error. API Key unavailable.")
                
        }
        return apiKey
    }
}