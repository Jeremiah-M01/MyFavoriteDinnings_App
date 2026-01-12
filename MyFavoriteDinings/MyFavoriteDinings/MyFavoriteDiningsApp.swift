//
//  MyFavoriteDiningsApp.swift
//  MyFavoriteDinings
//
//  Created by Jeremiah Martinez on 11/25/25.
//

import SwiftUI
import SwiftData

@main
struct MyFavoriteDiningsApp: App {
    

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Accounts.self)
    }
}
