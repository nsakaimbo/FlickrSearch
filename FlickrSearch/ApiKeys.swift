//
//  APIKeys.swift
//  FlickrSearch
//
//  Created by Nicholas Sakaimbo on 6/12/16.
//  Copyright © 2016 Richard turton. All rights reserved.
//

import Foundation

enum APIKeys {
    
    case flickr
    
    private var name: String {
        switch self {
        case .flickr: return "FlickrAPIKey"
        }
    }
    
    var key: String {
       
        let keyname = self.name
        
        guard let filePath = Bundle.main().pathForResource("ApiKeys", ofType:"plist"),
            plist = NSDictionary(contentsOfFile:filePath),
            apiKey = plist.object(forKey: keyname) as? String else {
                
                fatalError("Error. API Key unavailable.")
                
        }
        return apiKey
    }
}
