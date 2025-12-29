//
//  models.swift
//  MyFavoriteDinings
//
//  Created by Jeremiah Martinez on 11/25/25.
//

import Foundation
import SwiftData

@Model
final class Accounts {
    var username: String
    var password: String
    var restaurants: [Restaurant] = []
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
}

@Model
final class Restaurant {
    
    // Start implementing Restaurant logic
    var name: String
    var notes: String?
    var latitude: Double
    var longitude: Double
    var photos: [Data] = []
    var isPublic: Bool
    
    init(name: String, latitude: Double, longitude:Double, notes: String? = nil, photos: [Data] = []) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.photos = photos
        self.isPublic = false
    }
}
