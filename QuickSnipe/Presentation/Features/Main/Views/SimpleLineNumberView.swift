//
//  SimpleLineNumberView.swift
//  QuickSnipe
//
//  Created by QuickSnipe on 2025/06/30.
//

import SwiftUI
import AppKit

// シンプルで正確な行番号表示の実装
struct SimpleLineNumberView: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let onScrollChange: ((CGFloat) -> Void)?
    @ObservedObject private var fontManager = FontManager.shared
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // テキストビューの設定
        setupTextView(textView, context: context)
        
        // 段落スタイルの設定
        let lineHeight = calculateFixedLineHeight(for: font)
        let paragraphStyle = createParagraphStyle(lineHeight: lineHeight)
        setupParagraphStyle(textView: textView, paragraphStyle: paragraphStyle)
        
        // スクロールビューの設定
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // カスタムルーラービューを設定
        let lineNumberView = SimpleLineNumberRulerView(textView: textView)
        lineNumberView.fixedLineHeight = lineHeight // 固定行高を渡す
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        // 参照を保存
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.paragraphStyle = paragraphStyle
        context.coordinator.fontManager = fontManager
        context.coordinator.setupNotifications()
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // フォントを更新
        textView.font = font
        
        // 段落スタイルを設定
        let lineHeight = calculateFixedLineHeight(for: font)
        let paragraphStyle = createParagraphStyle(lineHeight: lineHeight)
        context.coordinator.paragraphStyle = paragraphStyle
        
        // テキストビューに適用
        applyParagraphStyle(
            to: textView,
            paragraphStyle: paragraphStyle,
            text: text,
            font: font
        )
        
        // 行番号ビューを更新
        updateLineNumberView(scrollView: scrollView, lineHeight: lineHeight)
    }
    
    private func createParagraphStyle(lineHeight: CGFloat) -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineHeightMultiple = 1.0
        paragraphStyle.lineSpacing = 0
        return paragraphStyle
    }
    
    private func applyParagraphStyle(
        to textView: NSTextView,
        paragraphStyle: NSMutableParagraphStyle,
        text: String,
        font: NSFont
    ) {
        textView.defaultParagraphStyle = paragraphStyle
        
        // IME入力中はテキストの同期をスキップ
        if !textView.hasMarkedText() && textView.string != text {
            textView.string = text
        }
        
        // 段落スタイルを適用（IME入力中はスキップ）
        if !textView.hasMarkedText() && !textView.string.isEmpty {
            let range = NSRange(location: 0, length: textView.string.count)
            textView.textStorage?.beginEditing()
            textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            textView.textStorage?.endEditing()
        }
        
        // タイピング属性も更新
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.labelColor
        ]
        
        // テキストコンテナの最小サイズを維持
        if let textContainer = textView.textContainer {
            textContainer.size = NSSize(width: textContainer.size.width, height: 100000)
        }
    }
    
    private func setupTextView(_ textView: NSTextView, context: Context) {
        textView.delegate = context.coordinator
        textView.font = font
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        
        // CotEditorから学んだ重要な設定
        textView.layoutManager?.usesFontLeading = false
        
        // カスタムレイアウトマネージャーを設定
        if let layoutManager = textView.layoutManager {
            layoutManager.delegate = context.coordinator
        }
        
        // テキストコンテナの設定
        let verticalPadding = fontManager.editorLayoutSettings.verticalPadding
        textView.textContainerInset = NSSize(width: 8, height: verticalPadding)
        if let textContainer = textView.textContainer {
            textContainer.lineFragmentPadding = 0
            textContainer.size = NSSize(width: textContainer.size.width, height: 100000)
        }
    }
    
    private func setupParagraphStyle(textView: NSTextView, paragraphStyle: NSParagraphStyle) {
        textView.defaultParagraphStyle = paragraphStyle
        
        // 既存のテキストに適用
        if !text.isEmpty {
            let range = NSRange(location: 0, length: text.count)
            textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
        
        // タイピング属性にも設定
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.labelColor
        ]
    }
    
    private func updateLineNumberView(scrollView: NSScrollView, lineHeight: CGFloat) {
        if scrollView.verticalRulerView == nil {
            guard let textView = scrollView.documentView as? NSTextView else { return }
            let lineNumberView = SimpleLineNumberRulerView(textView: textView)
            lineNumberView.fixedLineHeight = lineHeight
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        } else if let lineNumberView = scrollView.verticalRulerView as? SimpleLineNumberRulerView {
            lineNumberView.fixedLineHeight = lineHeight
        }
        
        scrollView.verticalRulerView?.needsDisplay = true
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSLayoutManagerDelegate {
        var parent: SimpleLineNumberView
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var paragraphStyle = NSMutableParagraphStyle()
        var fontManager: FontManager?
        private var notificationObserver: NSObjectProtocol?
        
        init(_ parent: SimpleLineNumberView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func setupNotifications() {
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .editorLayoutSettingsChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateLayout()
            }
        }
        
        func updateLayout() {
            guard let textView = textView else { return }
            
            // 再計算と再描画
            let font = textView.font ?? NSFont.systemFont(ofSize: 14)
            let lineHeight = calculateFixedLineHeight(for: font)
            let paragraphStyle = parent.createParagraphStyle(lineHeight: lineHeight)
            
            textView.defaultParagraphStyle = paragraphStyle
            self.paragraphStyle = paragraphStyle
            
            // テキストコンテナのパディングを更新
            let verticalPadding = fontManager?.editorLayoutSettings.verticalPadding ?? 4.0
            textView.textContainerInset = NSSize(width: 8, height: verticalPadding)
            
            if !textView.string.isEmpty {
                let range = NSRange(location: 0, length: textView.string.count)
                textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            }
            
            // 行番号ビューを更新
            if let lineNumberView = scrollView?.verticalRulerView as? SimpleLineNumberRulerView {
                lineNumberView.fixedLineHeight = lineHeight
                lineNumberView.needsDisplay = true
            }
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // IME入力中（marked text がある場合）は処理をスキップ
            if textView.hasMarkedText() {
                return
            }
            
            parent.text = textView.string
            
            // 日本語対応の段落スタイルを維持
            let font = textView.font ?? NSFont.systemFont(ofSize: 14)
            let lineHeight = calculateFixedLineHeight(for: font)
            let paragraphStyle = parent.createParagraphStyle(lineHeight: lineHeight)
            
            if !textView.string.isEmpty {
                let range = NSRange(location: 0, length: textView.string.count)
                textView.textStorage?.beginEditing()
                textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                textView.textStorage?.endEditing()
            }
            
            // デフォルトスタイルも更新
            textView.defaultParagraphStyle = paragraphStyle
            self.paragraphStyle = paragraphStyle
            
            // タイピング属性も維持
            textView.typingAttributes = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: NSColor.labelColor
            ]
            
            // 行番号を更新
            scrollView?.verticalRulerView?.needsDisplay = true
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            // 選択範囲が変更されたときに行番号エリアを再描画
            scrollView?.verticalRulerView?.needsDisplay = true
        }
        
        // MARK: - NSLayoutManagerDelegate
        
        func layoutManager(
            _ layoutManager: NSLayoutManager,
            shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
            lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
            baselineOffset: UnsafeMutablePointer<CGFloat>,
            in textContainer: NSTextContainer,
            forGlyphRange glyphRange: NSRange
        ) -> Bool {
            // 固定行高を強制
            guard let textView = textView,
                  let font = textView.font else { return false }
            
            let fixedLineHeight = calculateFixedLineHeight(for: font)
            
            // 行の高さを固定値に強制設定
            let currentHeight = lineFragmentRect.pointee.height
            if currentHeight < fixedLineHeight {
                // 行フラグメントの高さを固定値に設定
                lineFragmentRect.pointee.size.height = fixedLineHeight
                lineFragmentUsedRect.pointee.size.height = fixedLineHeight
            }
            
            // テキストのベースラインオフセットを調整
            let textBaselineOffset = fontManager?.editorLayoutSettings.textBaselineOffset ?? 0.0
            
            // ベースラインを行の中央に配置
            let lineCenter = fixedLineHeight / 2.0
            let fontHeight = font.ascender - font.descender
            let newBaseline = lineCenter + (fontHeight / 2.0) + font.descender
            
            baselineOffset.pointee = newBaseline + textBaselineOffset
            
            return true
        }
    }
}

// 行番号描画のコンテキストを表す構造体
private struct LineNumberDrawingContext {
    let textView: NSTextView
    let layoutManager: NSLayoutManager
    let textContainer: NSTextContainer
    let fullText: NSString
    let textAttributes: [NSAttributedString.Key: Any]
    let rect: NSRect
    let fontSize: CGFloat
}

// 行番号描画のパラメータをまとめた構造体
private struct DrawLineNumberParams {
    let lineRect: NSRect
    let glyphRange: NSRange
    var currentLineNumber: Int
    var drawnLineNumbers: Set<Int>
    let lineNumberFont: NSFont
    let visibleRect: NSRect
    let containerOrigin: NSPoint
    let textContainerInset: NSSize
}

// シンプルな行番号ルーラービュー
class SimpleLineNumberRulerView: NSRulerView {
    weak var textView: NSTextView?
    var fixedLineHeight: CGFloat = 20 // 固定行高
    let fontManager = FontManager.shared
    
    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.ruleThickness = 40
        self.clientView = textView
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        // 背景と境界線を描画
        drawBackground(in: rect)
        drawBorder(in: rect)
        
        // フォント設定
        let (fontSize, textAttributes) = setupFontAttributes(textView: textView)
        
        // 全テキストの処理
        let fullText = textView.string as NSString
        
        // テキストが空の場合でも行番号1を表示
        if fullText.length == 0 {
            drawEmptyTextLineNumber(
                textView: textView,
                layoutManager: layoutManager,
                textContainer: textContainer,
                textAttributes: textAttributes,
                fontSize: fontSize
            )
            return
        }
        
        // 選択された行の処理
        let selectedRange = textView.selectedRange()
        let selectedLineNumber = calculateSelectedLineNumber(
            fullText: fullText,
            selectedRange: selectedRange
        )
        
        drawSelectedLineBackground(
            textView: textView,
            layoutManager: layoutManager,
            fullText: fullText,
            selectedLineNumber: selectedLineNumber
        )
        
        // 行番号を描画
        let drawingContext = LineNumberDrawingContext(
            textView: textView,
            layoutManager: layoutManager,
            textContainer: textContainer,
            fullText: fullText,
            textAttributes: textAttributes,
            rect: rect,
            fontSize: fontSize
        )
        drawLineNumbers(context: drawingContext)
        
        // 最後の空行の処理
        drawLastEmptyLine(
            fullText: fullText,
            layoutManager: layoutManager,
            textView: textView,
            textAttributes: textAttributes,
            rect: rect,
            fontSize: fontSize
        )
    }
    
    // MARK: - Helper Methods
    
    private func drawBackground(in rect: NSRect) {
        NSColor.controlBackgroundColor.withAlphaComponent(0.5).set()
        rect.fill()
    }
    
    private func drawBorder(in rect: NSRect) {
        NSColor.separatorColor.set()
        let borderPath = NSBezierPath()
        borderPath.move(to: NSPoint(x: ruleThickness - 0.5, y: 0))
        borderPath.line(to: NSPoint(x: ruleThickness - 0.5, y: rect.height))
        borderPath.lineWidth = 1.0
        borderPath.stroke()
    }
    
    private func setupFontAttributes(textView: NSTextView) -> (CGFloat, [NSAttributedString.Key: Any]) {
        let fontSize = textView.font?.pointSize ?? 14
        let lineNumberFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.7, weight: .regular)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: lineNumberFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        return (fontSize, textAttributes)
    }
    
    private func calculateSelectedLineNumber(fullText: NSString, selectedRange: NSRange) -> Int {
        // パフォーマンス最適化：選択位置までのテキストのみを処理
        if selectedRange.location == 0 {
            return 1
        }
        
        // 改行を直接カウント（配列作成を回避）
        let textBeforeSelection = fullText.substring(to: min(selectedRange.location, fullText.length))
        return textBeforeSelection.components(separatedBy: "\n").count
    }
    
    private func drawSelectedLineBackground(
        textView: NSTextView,
        layoutManager: NSLayoutManager,
        fullText: NSString,
        selectedLineNumber: Int
    ) {
        let visibleRect = textView.visibleRect
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textView.textContainer!)
        let extendedGlyphRange = NSRange(
            location: max(0, visibleGlyphRange.location),
            length: min(visibleGlyphRange.length + 1000, layoutManager.numberOfGlyphs - visibleGlyphRange.location)
        )
        
        // 基準点を正しく計算
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let containerOrigin = textView.textContainerOrigin
        
        layoutManager.enumerateLineFragments(forGlyphRange: extendedGlyphRange) { lineRect, _, _, glyphRange, _ in
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            // この行フラグメントの行番号を正確に計算
            let textBeforeRange = fullText.substring(to: min(characterRange.location, fullText.length))
            let thisLineNumber = textBeforeRange.components(separatedBy: "\n").count
            
            // 選択された行番号と一致するかチェック
            if thisLineNumber == selectedLineNumber {
                // 正しい Y 位置計算
                let lineY = lineRect.minY + containerOrigin.y + relativePoint.y
                
                NSColor.selectedTextBackgroundColor.withAlphaComponent(0.2).set()
                let path = NSBezierPath(rect: NSRect(
                    x: 0,
                    y: lineY,
                    width: self.ruleThickness,
                    height: lineRect.height
                ))
                path.fill()
            }
        }
    }
    
    private func drawEmptyTextLineNumber(
        textView: NSTextView,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        textAttributes: [NSAttributedString.Key: Any],
        fontSize: CGFloat
    ) {
        let lineString = "1"
        let size = lineString.size(withAttributes: textAttributes)
        let lineNumberFont = textAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: fontSize)
        
        // 基準点の計算（drawLineNumbersと同じ）
        let visibleRect = textView.visibleRect
        let containerOrigin = textView.textContainerOrigin
        let textContainerInset = textView.textContainerInset
        
        // 固定行高を使用（テキスト入力時と同じ高さを確保）
        // 段落スタイルから固定行高を取得
        let paragraphStyle = textView.defaultParagraphStyle
        let lineHeight = paragraphStyle?.minimumLineHeight ?? fixedLineHeight
        
        // 最初の行の矩形を仮想的に計算（固定行高を使用）
        let lineRect = NSRect(x: 0, y: 0, width: 100, height: lineHeight)
        
        // Y位置の計算（実際のレイアウトと同じ計算）
        let lineY = lineRect.origin.y + containerOrigin.y - visibleRect.origin.y
        
        // 行の中央に配置するための計算
        let lineNumberHeight = lineNumberFont.ascender - lineNumberFont.descender
        
        // 行の中央位置を計算
        let lineCenterY = lineY + textContainerInset.height + (lineHeight / 2)
        
        // 行番号を中央に配置（設定値でオフセット調整）
        let offset = fontManager.editorLayoutSettings.lineNumberVerticalOffset
        let drawingY = lineCenterY - (lineNumberHeight / 2) - lineNumberFont.descender + offset
        
        let drawingPoint = NSPoint(
            x: self.ruleThickness - size.width - 5,
            y: drawingY
        )
        
        lineString.draw(at: drawingPoint, withAttributes: textAttributes)
    }
    
    private func drawLineNumbers(context: LineNumberDrawingContext) {
        let lineNumberFont = context.textAttributes[.font] as? NSFont ??
            NSFont.systemFont(ofSize: context.fontSize)
        
        // 基準点の計算
        let visibleRect = context.textView.visibleRect
        let containerOrigin = context.textView.textContainerOrigin
        let textContainerInset = context.textView.textContainerInset
        
        // 可視範囲のグリフ範囲を取得
        let visibleGlyphRange = context.layoutManager.glyphRange(
            forBoundingRect: visibleRect,
            in: context.textContainer
        )
        
        // 拡張範囲（スクロール時のちらつき防止）
        let startLoc = max(0, visibleGlyphRange.location - 500)
        let maxLength = context.layoutManager.numberOfGlyphs - startLoc
        let extendedGlyphRange = NSRange(
            location: startLoc,
            length: min(visibleGlyphRange.length + 1000, maxLength)
        )
        
        // 描画済み行番号を記録（重複描画を防ぐ）
        var drawnLineNumbers = Set<Int>()
        
        // 行番号を計算するための初期値
        var currentLineNumber = 1
        if extendedGlyphRange.location > 0 {
            currentLineNumber = calculateInitialLineNumber(
                context: context,
                extendedGlyphRange: extendedGlyphRange
            )
        }
        
        // 各行フラグメントに対して処理
        context.layoutManager.enumerateLineFragments(
            forGlyphRange: extendedGlyphRange
        ) { lineRect, _, _, glyphRange, _ in
            var params = DrawLineNumberParams(
                lineRect: lineRect,
                glyphRange: glyphRange,
                currentLineNumber: currentLineNumber,
                drawnLineNumbers: drawnLineNumbers,
                lineNumberFont: lineNumberFont,
                visibleRect: visibleRect,
                containerOrigin: containerOrigin,
                textContainerInset: textContainerInset
            )
            self.drawLineNumber(context: context, params: &params)
            currentLineNumber = params.currentLineNumber
            drawnLineNumbers = params.drawnLineNumbers
        }
    }
    
    private func calculateInitialLineNumber(
        context: LineNumberDrawingContext,
        extendedGlyphRange: NSRange
    ) -> Int {
        let range = NSRange(location: 0, length: extendedGlyphRange.location)
        let characterRange = context.layoutManager.characterRange(
            forGlyphRange: range,
            actualGlyphRange: nil
        )
        
        let textBeforeVisible = context.fullText.substring(
            to: min(characterRange.location, context.fullText.length)
        )
        return textBeforeVisible.components(separatedBy: "\n").count
    }
    
    private func drawLineNumber(
        context: LineNumberDrawingContext,
        params: inout DrawLineNumberParams
    ) {
        let characterRange = context.layoutManager.characterRange(
            forGlyphRange: params.glyphRange,
            actualGlyphRange: nil
        )
        
        // Y位置の計算
        let lineY = params.lineRect.origin.y + params.containerOrigin.y - params.visibleRect.origin.y
        
        // 描画範囲内かチェック
        if lineY + self.fixedLineHeight >= -50 && lineY <= context.rect.height + 50 {
            // 重複描画を防ぐ
            if !params.drawnLineNumbers.contains(params.currentLineNumber) {
                params.drawnLineNumbers.insert(params.currentLineNumber)
                
                let lineString = "\(params.currentLineNumber)"
                let size = lineString.size(withAttributes: context.textAttributes)
                
                // 行の中央に配置するための計算
                let lineNumberHeight = params.lineNumberFont.ascender - params.lineNumberFont.descender
                let lineCenterY = lineY + params.textContainerInset.height + (params.lineRect.height / 2)
                
                // 行番号を中央に配置（設定値でオフセット調整）
                let offset = self.fontManager.editorLayoutSettings.lineNumberVerticalOffset
                let drawingY = lineCenterY - (lineNumberHeight / 2) -
                    params.lineNumberFont.descender + offset
                
                let drawingPoint = NSPoint(
                    x: self.ruleThickness - size.width - 5,
                    y: drawingY
                )
                
                lineString.draw(at: drawingPoint, withAttributes: context.textAttributes)
            }
        }
        
        // 次の行番号を計算（改行文字の数を数える）
        if characterRange.location + characterRange.length <= context.fullText.length {
            let lineText = context.fullText.substring(with: characterRange)
            let newlineCount = lineText.components(separatedBy: "\n").count - 1
            params.currentLineNumber += max(1, newlineCount)
        }
    }
    
    private func drawLastEmptyLine(
        fullText: NSString,
        layoutManager: NSLayoutManager,
        textView: NSTextView,
        textAttributes: [NSAttributedString.Key: Any],
        rect: NSRect,
        fontSize: CGFloat
    ) {
        // パフォーマンス最適化：最後の文字のみをチェック
        guard fullText.length > 0 && fullText.hasSuffix("\n") else { return }
        
        // 最後の改行までの行数を効率的に計算
        let totalLineCount = fullText.components(separatedBy: "\n").count
        
        // 最後の空行の処理（テキストが改行で終わる場合）
        if fullText.length > 0 && fullText.hasSuffix("\n") {
            let lastLineNumber = totalLineCount
            if !(drawnLines ?? Set<Int>()).contains(lastLineNumber) {
                // 最後の行の位置を計算
                let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: fullText.length - 1)
                if lastGlyphIndex < layoutManager.numberOfGlyphs {
                    let lastLineRect = layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
                    
                    // 基準点を正しく計算
                    let relativePoint = self.convert(NSPoint.zero, from: textView)
                    let containerOrigin = textView.textContainerOrigin
                    
                    // 最後の空行のY位置計算
                    let lineY = lastLineRect.maxY + containerOrigin.y + relativePoint.y
                    
                    if lineY >= -50 && lineY <= rect.height + 50 {
                        let lineString = "\(lastLineNumber)"
                        let size = lineString.size(withAttributes: textAttributes)
                        
                        let lineNumberFont = textAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: fontSize)
                        
                        // 他の行と同じ計算方法を使用
                        let lineNumberHeight = lineNumberFont.ascender - lineNumberFont.descender
                        
                        // 行の中央位置を計算（固定行高を使用）
                        let lineCenterY = lineY + textView.textContainerInset.height + (fixedLineHeight / 2)
                        
                        // 行番号を中央に配置（設定値でオフセット調整）
                        let offset = fontManager.editorLayoutSettings.lineNumberVerticalOffset
                        let drawingY = lineCenterY - (lineNumberHeight / 2) - lineNumberFont.descender + offset
                        
                        let drawingPoint = NSPoint(
                            x: self.ruleThickness - size.width - 5,
                            y: drawingY
                        )
                        
                        lineString.draw(at: drawingPoint, withAttributes: textAttributes)
                    }
                }
            }
        }
    }
    
    // 描画済みの行番号を記録するための一時的なプロパティ
    private var drawnLines: Set<Int>?
    
    // 日本語フォントかどうかを判定
    private func isJapaneseFont(_ font: NSFont) -> Bool {
        let fontName = font.fontName.lowercased()
        return font.fontName.contains("Hiragino") ||
               font.fontName.contains("Yu") ||
               font.fontName.contains("Osaka") ||
               font.fontName.contains("Noto") && (fontName.contains("jp") || fontName.contains("cjk")) ||
               font.fontName.contains("Source Han") ||
               font.fontName.contains("ヒラギノ") ||
               font.fontName.contains("游") ||
               fontName.contains("gothic") ||
               fontName.contains("mincho")
    }
}

// 固定行高を計算するヘルパー関数
private func calculateFixedLineHeight(for font: NSFont) -> CGFloat {
    let fontManager = FontManager.shared
    
    // 基本フォントの高さ
    var maxHeight = font.ascender - font.descender
    
    // 日本語フォントの代表的なものも考慮
    let japaneseTestFonts = ["HiraginoSans-W3", "YuGothic-Medium", "NotoSansCJK-Regular"]
    for fontName in japaneseTestFonts {
        if let japaneseFont = NSFont(name: fontName, size: font.pointSize) {
            let height = japaneseFont.ascender - japaneseFont.descender
            maxHeight = max(maxHeight, height)
        }
    }
    
    // CJKテキストに適した余白（設定値を使用）
    let recommendedHeight = maxHeight * fontManager.editorLayoutSettings.lineHeightMultiplier
    
    // 最小値を保証（設定値を使用）
    let minimumHeight = font.pointSize * fontManager.editorLayoutSettings.minimumLineHeightMultiplier
    
    // 最終的な固定行高
    return ceil(max(recommendedHeight, minimumHeight))
}
