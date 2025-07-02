//
//  ClipboardServiceTests.swift
//  QuickSnipeTests
//
//  Created by QuickSnipe on 2025/06/29.
//

import XCTest
@testable import QuickSnipe

final class ClipboardServiceTests: XCTestCase {
    var clipboardService: ClipboardService!
    
    override func setUp() {
        super.setUp()
        clipboardService = ClipboardService.shared
        // テスト開始前に履歴をクリア
        clipboardService.clearAllHistory()
    }
    
    override func tearDown() {
        clipboardService.stopMonitoring()
        // テスト終了後も履歴をクリア
        clipboardService.clearAllHistory()
        // UserDefaultsから大きなデータをクリア
        UserDefaults.standard.removeObject(forKey: "com.quicksnipe.clipboardHistory")
        UserDefaults.standard.synchronize()
        clipboardService = nil
        super.tearDown()
    }
    
    func testStartStopMonitoring() {
        // Given
        XCTAssertNotNil(clipboardService)
        
        // When
        clipboardService.startMonitoring()
        
        // Then
        // Monitor should be running (we can't directly test private properties)
        // Just ensure no crash occurs
        
        // When
        clipboardService.stopMonitoring()
        
        // Then
        // Monitor should be stopped
        // Just ensure no crash occurs
    }
    
    func testThreadSafety() {
        // This test ensures that multiple concurrent operations don't cause crashes
        let expectation = XCTestExpectation(description: "Thread safety test")
        let operationCount = 100
        let completedOperationsQueue = DispatchQueue(label: "test.counter")
        var completedOperations = 0
        
        // Start monitoring
        clipboardService.startMonitoring()
        
        // Perform concurrent operations
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<operationCount {
            queue.async {
                // Simulate clipboard operations
                if i % 3 == 0 {
                    self.clipboardService.copyToClipboard("Test content \(i)")
                } else if i % 3 == 1 {
                    _ = self.clipboardService.history.count
                } else {
                    self.clipboardService.clearAllHistory()
                }
                
                // Thread-safe counter increment
                completedOperationsQueue.async {
                    completedOperations += 1
                    if completedOperations == operationCount {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Ensure service is still functional
        clipboardService.stopMonitoring()
    }
    
    func testCopyToClipboard() {
        // Given
        let testContent = "Test clipboard content"
        
        // When
        clipboardService.copyToClipboard(testContent)
        
        // Then
        let pasteboardContent = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(pasteboardContent, testContent)
    }
    
    func testTogglePin() {
        // Given
        let item = ClipItem(content: "Test item", isPinned: false)
        clipboardService.history = [item]
        
        // When
        clipboardService.togglePin(for: item)
        
        // Then
        XCTAssertTrue(clipboardService.history.first?.isPinned ?? false)
        
        // When toggle again
        clipboardService.togglePin(for: item)
        
        // Then
        XCTAssertFalse(clipboardService.history.first?.isPinned ?? true)
    }
    
    func testClearAllHistory() {
        // Given
        let items = [
            ClipItem(content: "Item 1"),
            ClipItem(content: "Item 2"),
            ClipItem(content: "Item 3")
        ]
        clipboardService.history = items
        
        // When
        let expectation = XCTestExpectation(description: "Clear history")
        clipboardService.clearAllHistory()
        
        // Wait for async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertTrue(self.clipboardService.history.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}
