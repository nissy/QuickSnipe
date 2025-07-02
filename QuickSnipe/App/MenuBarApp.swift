//
//  MenuBarApp.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/28.
//

import SwiftUI
import Cocoa

final class MenuBarApp: NSObject, ObservableObject {
    private var statusBarItem: NSStatusItem?
    private let clipboardService = ClipboardService.shared
    private let windowManager = WindowManager()
    private let hotkeyManager = HotkeyManager()
    
    override init() {
        super.init()
        DispatchQueue.main.async { [weak self] in
            self?.setupMenuBar()
            self?.startServices()
            self?.hotkeyManager.delegate = self
        }
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.title = "📋"
            
            if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "QuickSnipe") {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
            }
            
            button.toolTip = "QuickSnipe - Clipboard Manager"
        }
        
        let menu = createMenu()
        statusBarItem?.menu = menu
        statusBarItem?.isVisible = true
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open QuickSnipe", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        #if DEBUG
        menu.addItem(NSMenuItem(title: "Developer Settings...", action: #selector(openDeveloperSettings), keyEquivalent: ""))
        #endif
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit QuickSnipe", action: #selector(quit), keyEquivalent: "q"))
        
        menu.items.forEach { $0.target = self }
        
        return menu
    }
    
    private func startServices() {
        clipboardService.startMonitoring()
    }
    
    @objc private func openMainWindow() {
        windowManager.openMainWindow()
    }
    
    @objc private func openPreferences() {
        windowManager.openSettings()
    }
    
    @objc private func showAbout() {
        windowManager.showAbout()
    }
    
    #if DEBUG
    @objc private func openDeveloperSettings() {
        windowManager.openDeveloperSettings()
    }
    #endif
    
    @objc private func quit() {
        clipboardService.stopMonitoring()
        windowManager.cleanup()
        // hotkeyManager は deinit で自動的にクリーンアップされる
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - HotkeyManagerDelegate
extension MenuBarApp: HotkeyManagerDelegate {
    func hotkeyPressed() {
        openMainWindow()
    }
}
