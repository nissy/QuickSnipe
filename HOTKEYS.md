# QuickSnipe ホットキー設定

## グローバルホットキー（システム全体で動作）

### メインホットキー
- **キー**: ⌘V (Command+V)
- **機能**: QuickSnipeウィンドウを開く/閉じる
- **有効**: ✅

### エディタコピーホットキー
- **キー**: ⌘⇧C (Command+Shift+C)  
- **機能**: エディタの内容をクリップボードにコピー
- **有効**: ✅

### エディタクリアホットキー
- **キー**: ⌘⇧X (Command+Shift+X)
- **機能**: エディタの内容をクリア
- **有効**: ✅ (手動で有効化済み)

## アプリ内ショートカット

### メインウィンドウ
- **⌘Return**: エディタ内容をコピー（Copyボタン）
- **⌘Delete**: エディタ内容をクリア（Clearボタン）

### メニューバー
- **⌘,**: 設定画面を開く
- **⌘Q**: アプリケーションを終了

### 設定画面
- **Escape**: ダイアログをキャンセル
- **Return**: ダイアログで選択を確定

## エディタ挿入モード
- **有効**: ✅
- **モディファイアキー**: ⇧ (Shift)
- **使い方**: Shiftを押しながら履歴項目をクリックすると、エディタに挿入される

## トラブルシューティング

### ホットキーが動作しない場合

1. **設定画面から有効化を確認**
   - Preferences → General → 各ホットキーのトグルをONにする

2. **手動で有効化する場合**
   ```bash
   # メインホットキーを有効化
   defaults write com.nissy.QuickSnipe enableHotkey -bool true
   
   # エディタコピーホットキーを有効化
   defaults write com.nissy.QuickSnipe enableEditorCopyHotkey -bool true
   
   # エディタクリアホットキーを有効化
   defaults write com.nissy.QuickSnipe enableEditorClearHotkey -bool true
   ```

3. **アプリケーションを再起動**
   - QuickSnipeを完全に終了して再起動してください

### キーコード参照

| キー | キーコード |
|-----|-----------|
| Z   | 6         |
| X   | 7         |
| C   | 8         |
| V   | 9         |
| Q   | 12        |
| M   | 46        |

### モディファイアフラグ参照

| モディファイア | 値      |
|---------------|---------|
| Command (⌘)   | 262144  |
| Control (⌃)   | 1048576 |
| Option (⌥)    | 524288  |
| Shift (⇧)     | 131072  |

## 注意事項

- ホットキーの変更後は必ずアプリケーションを再起動してください
- macOSのセキュリティ設定でアクセシビリティの許可が必要な場合があります
- System Preferences → Security & Privacy → Privacy → Accessibility でQuickSnipeを許可してください