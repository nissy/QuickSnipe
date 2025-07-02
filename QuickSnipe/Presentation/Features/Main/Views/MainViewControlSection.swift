//
//  MainViewControlSection.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/30.
//

import SwiftUI

struct MainViewControlSection: View {
    let onCopy: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(ProminentButtonStyle())
            .keyboardShortcut(.return, modifiers: .command)
            .fixedSize()
            
            Spacer()
            
            Button(action: onClear) {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(DestructiveButtonStyle())
            .keyboardShortcut(.delete, modifiers: .command)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
