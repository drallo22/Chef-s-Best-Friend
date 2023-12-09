//
//  Chef_s_Best_FriendApp.swift
//  Chef's Best Friend
//
//  Created by David Rallo on 2023-10-18.
//

import SwiftUI
import FirebaseCore
import Firebase

@main
struct Chef_s_Best_FriendApp: App {
    
    init() {
    FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
