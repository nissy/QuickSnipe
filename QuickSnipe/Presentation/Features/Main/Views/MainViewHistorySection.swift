//
//  MainViewHistorySection.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/30.
//

import SwiftUI
import Combine

struct MainViewHistorySection: View {
    let history: [ClipItem]
    @Binding var selectedHistoryItem: ClipItem?
    @Binding var hoveredHistoryItem: ClipItem?
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchCancellable: AnyCancellable?
    let onSelectItem: (ClipItem) -> Void
    let onTogglePin: (ClipItem) -> Void
    let onDelete: ((ClipItem) -> Void)?
    
    var body: some View {
        let filteredHistory = debouncedSearchText.isEmpty ? history : 
            history.filter { $0.content.localizedCaseInsensitiveContains(debouncedSearchText) }
        
        return VStack(spacing: 0) {
            // ヘッダー
            HStack(spacing: 10) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, y: 2)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Clipboard History")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 履歴数を表示
                if !history.isEmpty {
                    Text("\(history.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: { 
                    withAnimation(.spring()) { 
                        isSearching.toggle() 
                    } 
                }, label: {
                    ZStack {
                        Circle()
                            .fill(isSearching ? 
                                Color.accentColor : 
                                Color(NSColor.controlBackgroundColor))
                            .frame(width: 28, height: 28)
                            .shadow(
                                color: isSearching ? 
                                    Color.accentColor.opacity(0.3) : 
                                    Color.black.opacity(0.05),
                                radius: 3,
                                y: 1
                            )
                        
                        Image(systemName: isSearching ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSearching ? .white : .secondary)
                    }
                })
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isSearching ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSearching)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color(NSColor.windowBackgroundColor).opacity(0.9)
            )
            
            // 検索バー
            if isSearching {
                HStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(NSColor.textBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, y: 2)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.leading, 10)
                            
                            TextField("Search clipboard history...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                            
                            if !searchText.isEmpty {
                                Button(action: { 
                                    withAnimation(.spring(response: 0.2)) {
                                        searchText = ""
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                })
                                .buttonStyle(PlainButtonStyle())
                                .padding(.trailing, 10)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .frame(height: 36)
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            isSearching = false
                            searchText = ""
                        }
                    }, label: {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                    })
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // 履歴リスト
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredHistory) { item in
                        HistoryItemView(
                            item: item,
                            isSelected: selectedHistoryItem?.id == item.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    onSelectItem(item)
                                }
                            },
                            onTogglePin: {
                                withAnimation(.spring(response: 0.4)) {
                                    onTogglePin(item)
                                }
                            },
                            onDelete: onDelete != nil ? {
                                withAnimation(.spring(response: 0.3)) {
                                    onDelete?(item)
                                }
                            } : nil
                        )
                        .onHover { hovering in
                            hoveredHistoryItem = hovering ? item : nil
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                Color(NSColor.controlBackgroundColor).opacity(0.3)
            )
        }
        .onChange(of: searchText) { newValue in
            // 検索テキストの変更をデバウンス（パフォーマンス最適化）
            searchCancellable?.cancel()
            searchCancellable = Just(newValue)
                .delay(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { value in
                    debouncedSearchText = value
                }
        }
    }
}
