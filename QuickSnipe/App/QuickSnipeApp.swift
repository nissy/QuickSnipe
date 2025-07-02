//
//  QuickSnipeApp.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/28.
//

import SwiftUI

@main
struct QuickSnipeApp: App {
    @StateObject private var menuBarApp = MenuBarApp()
    
    init() {
        // App initialization
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
