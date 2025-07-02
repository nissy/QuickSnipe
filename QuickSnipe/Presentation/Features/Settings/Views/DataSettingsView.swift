//
//  DataSettingsView.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/07/02.
//

import SwiftUI

struct DataSettingsView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    @AppStorage("maxPinnedItems") private var maxPinnedItems = 10
    
    var body: some View {
        VStack(spacing: 14) {
            // Font Settings
            ClipboardFontSettingsView()
            
            Divider()
                .padding(.vertical, 8)
            
            // Storage Limits Section
            SettingsSection(
                icon: "externaldrive",
                iconColor: .orange,
                title: "Storage Limits"
            ) {
                VStack(spacing: 14) {
                    // Maximum history items
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum History Items:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            TextField(
                                "",
                                value: Binding(
                                    get: { Double(maxHistoryItems) },
                                    set: { maxHistoryItems = Int($0) }
                                ),
                                formatter: NumberFormatter()
                            )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            Stepper(
                                "",
                                value: Binding(
                                    get: { Double(maxHistoryItems) },
                                    set: { maxHistoryItems = Int($0) }
                                ),
                                in: 10...1000,
                                step: 10
                            )
                                .labelsHidden()
                            
                            Spacer()
                        }
                        
                        Text("Maximum number of clipboard history items to keep")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Maximum pinned items
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Pinned Items:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            TextField(
                                "",
                                value: Binding(
                                    get: { Double(maxPinnedItems) },
                                    set: { maxPinnedItems = Int($0) }
                                ),
                                formatter: NumberFormatter()
                            )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            Stepper(
                                "",
                                value: Binding(
                                    get: { Double(maxPinnedItems) },
                                    set: { maxPinnedItems = Int($0) }
                                ),
                                in: 1...100,
                                step: 1
                            )
                                .labelsHidden()
                            
                            Spacer()
                        }
                        
                        Text("Maximum number of items that can be pinned")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}
