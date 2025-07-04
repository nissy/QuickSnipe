//
//  HistoryItemViewTests.swift
//  QuickSnipeTests
//
//  Created by QuickSnipe on 2025/06/28.
//

import XCTest
import SwiftUI
@testable import QuickSnipe

final class HistoryItemViewTests: XCTestCase {
    
    func testHistoryItemViewInitialization() {
        // Given
        let item = ClipItem(content: "Test content")
        var tapCalled = false
        var togglePinCalled = false
        
        // When
        let view = HistoryItemView(
            item: item,
            isSelected: false,
            onTap: { tapCalled = true },
            onTogglePin: { togglePinCalled = true },
            onDelete: nil
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertFalse(tapCalled)
        XCTAssertFalse(togglePinCalled)
    }
    
    func testHistoryItemViewDisplay() {
        // Given
        let item = ClipItem(content: "This is a very long content that should be truncated in the display")
        
        // When
        _ = HistoryItemView(
            item: item,
            isSelected: false,
            onTap: {},
            onTogglePin: {},
            onDelete: nil
        )
        
        // Then
        XCTAssertEqual(item.displayContent, "This is a very long content that should be truncat...")
    }
    
    func testClipboardItemPopover() {
        // Given
        let content = "Test content for popover"
        let item = ClipItem(content: content)
        
        // When
        let popover = ClipboardItemPopover(item: item)
        
        // Then
        XCTAssertNotNil(popover)
        XCTAssertEqual(item.fullContent, content)
        XCTAssertEqual(item.characterCount, content.count)
    }
}
