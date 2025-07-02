//
//  MainViewModel.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/28.
//

import Foundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var editorText: String {
        didSet {
            // エディタのテキストが変更されたら保存
            if !editorText.isEmpty {
                UserDefaults.standard.set(editorText, forKey: "lastEditorText")
            } else {
                // 空の場合は保存を削除
                UserDefaults.standard.removeObject(forKey: "lastEditorText")
            }
        }
    }
    
    private let clipboardService: ClipboardServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var history: [ClipItem] = []
    @Published var pinnedItems: [ClipItem] = []
    
    init(clipboardService: ClipboardServiceProtocol = ClipboardService.shared) {
        // 保存されたエディタテキストを読み込む（なければ空文字）
        self.editorText = UserDefaults.standard.string(forKey: "lastEditorText") ?? ""
        self.clipboardService = clipboardService
        
        // Subscribe to clipboard service changes
        if let observableService = clipboardService as? ClipboardService {
            observableService.$history
            .sink { [weak self] items in
                guard let self = self else { return }
                self.updateFilteredItems(items)
            }
            .store(in: &cancellables)
        }
        
        // 設定値の変更を監視
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // 設定値が変更されたら再フィルタリング
                self.updateFilteredItems(self.clipboardService.history)
            }
            .store(in: &cancellables)
        
        // 初回読み込み
        updateFilteredItems(clipboardService.history)
    }
    
    private func updateFilteredItems(_ items: [ClipItem]) {
        self.history = items.filter { !$0.isPinned }
        self.pinnedItems = items.filter { $0.isPinned }
    }
    
    func copyEditor() {
        if !editorText.isEmpty {
            clipboardService.copyToClipboard(editorText, fromEditor: true)
            // コピー後にテキストをクリア
            editorText = ""
            UserDefaults.standard.removeObject(forKey: "lastEditorText")
        }
    }
    
    func clearEditor() {
        editorText = ""
        UserDefaults.standard.removeObject(forKey: "lastEditorText")
    }
    
    func selectHistoryItem(_ item: ClipItem) {
        clipboardService.copyToClipboard(item.content, fromEditor: false)
    }
    
    func togglePin(for item: ClipItem) {
        clipboardService.togglePin(for: item)
    }
    
    func deleteItem(_ item: ClipItem) {
        clipboardService.deleteItem(item)
    }
    
    func reorderPinnedItems(_ newOrder: [ClipItem]) {
        clipboardService.reorderPinnedItems(newOrder)
    }
    
    // MARK: - Editor Insert Functions
    
    /// エディタに内容を挿入（既存内容をクリア）
    func insertToEditor(content: String) {
        editorText = content
    }
    
    /// エディタ挿入機能が有効かチェック
    func isEditorInsertEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "enableEditorInsert")
    }
    
    /// 設定された修飾キーを取得
    func getEditorInsertModifiers() -> NSEvent.ModifierFlags {
        let rawValue = UserDefaults.standard.integer(forKey: "editorInsertModifiers")
        return NSEvent.ModifierFlags(rawValue: UInt(rawValue))
    }
    
    /// 現在の修飾キーがエディタ挿入用かチェック
    func shouldInsertToEditor() -> Bool {
        guard isEditorInsertEnabled() else { return false }
        
        let currentModifiers = NSEvent.modifierFlags
        let requiredModifiers = getEditorInsertModifiers()
        
        // 必要な修飾キーがすべて押されているかチェック
        return currentModifiers.intersection(requiredModifiers) == requiredModifiers
    }
    
    /// 履歴アイテム選択（修飾キー検出対応）
    func selectHistoryItem(_ item: ClipItem, forceInsert: Bool = false) {
        if forceInsert || shouldInsertToEditor() {
            insertToEditor(content: item.content)
        } else {
            clipboardService.copyToClipboard(item.content, fromEditor: false)
        }
    }
}
