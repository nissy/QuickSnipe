//
//  HotkeyManager.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/07/02.
//

import Foundation
import Carbon
import AppKit

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
}

final class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    
    private var hotKeyEventHandler: EventHandlerRef?
    private var currentHotKey: EventHotKeyRef?
    private var settingsObserver: NSObjectProtocol?
    private static var shared: HotkeyManager?
    
    init() {
        HotkeyManager.shared = self
        setupSettingsObserver()
        registerCurrentHotkey()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupSettingsObserver() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HotkeySettingsChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerCurrentHotkey()
        }
    }
    
    func registerCurrentHotkey() {
        // 既存のホットキーを削除
        unregisterHotkey()
        
        // AppStorageから設定を読み込み
        let enableHotkey = UserDefaults.standard.object(forKey: "enableHotkey") as? Bool ?? false // デフォルトで無効
        guard enableHotkey else { return }
        
        // キーコードとモディファイアフラグを読み込み
        let keyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        let modifierFlagsRaw = UserDefaults.standard.integer(forKey: "hotkeyModifierFlags")
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifierFlagsRaw))
        
        // デフォルト値の設定（初回起動時）
        if keyCode == 0 {
            UserDefaults.standard.set(9, forKey: "hotkeyKeyCode") // V key
            UserDefaults.standard.set(
                NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue, 
                forKey: "hotkeyModifierFlags"
            ) // CMD+OPT
            registerCurrentHotkey() // 再帰的に呼び出し
            return
        }
        
        // Carbon modifierを計算
        var carbonModifiers: UInt32 = 0
        if modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        
        // ホットキーを登録
        registerHotkey(keyCode: UInt32(keyCode), modifiers: carbonModifiers)
    }
    
    private func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        // イベントハンドラがなければ作成
        if hotKeyEventHandler == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            
            let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
                // staticな参照を使用
                HotkeyManager.shared?.handleHotkeyEvent()
                return noErr
            }
            
            InstallEventHandler(
                GetApplicationEventTarget(),
                handler,
                1,
                &eventType,
                nil, // userDataは使用しない
                &hotKeyEventHandler
            )
        }
        
        // ホットキーIDを作成
        let hotKeyID = EventHotKeyID(signature: OSType(0x514B5350), id: 1) // "QKSP" in hex
        
        // ホットキーを登録
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &currentHotKey)
    }
    
    private func unregisterHotkey() {
        if let hotKey = currentHotKey {
            UnregisterEventHotKey(hotKey)
            currentHotKey = nil
        }
    }
    
    private func handleHotkeyEvent() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.hotkeyPressed()
        }
    }
    
    private func cleanup() {
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
            settingsObserver = nil
        }
        
        unregisterHotkey()
        if let handler = hotKeyEventHandler {
            RemoveEventHandler(handler)
            hotKeyEventHandler = nil
        }
    }
}
