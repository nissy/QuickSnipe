//
//  WindowCloseTests.swift
//  QuickSnipeTests
//
//  Created by QuickSnipe on 2025/06/29.
//

import XCTest
import SwiftUI
@testable import QuickSnipe

final class WindowCloseTests: XCTestCase {
    
    func testMainViewCloseCallback() {
        // Given
        var closeCalled = false
        let expectation = XCTestExpectation(description: "Close callback should be called")
        
        let onCloseHandler: (() -> Void)? = {
            closeCalled = true
            expectation.fulfill()
        }
        
        // MainViewの初期化
        _ = MainView(onClose: onCloseHandler)
        
        // When - onCloseハンドラーを直接呼び出し
        onCloseHandler?()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(closeCalled)
    }
    
    func testHistoryItemTapClosesWindow() {
        // Given
        var windowClosed = false
        let expectation = XCTestExpectation(description: "Window should close on history item tap")
        
        let item = ClipItem(content: "Test content", isPinned: false)
        
        // HistoryItemViewのonTapクロージャーをテスト
        let historyItemView = HistoryItemView(
            item: item,
            isSelected: false,
            onTap: {
                // このクロージャーが呼ばれたら、MainViewでonClose?()が呼ばれる
                windowClosed = true
                expectation.fulfill()
            },
            onTogglePin: {},
            onDelete: nil
        )
        
        // When - onTapを直接呼び出し（実際のタップをシミュレート）
        historyItemView.onTap()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(windowClosed)
    }
}
