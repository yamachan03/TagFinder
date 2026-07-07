# ROADMAP — 今後実装したい機能のプラン

作成日: 2026-07-07

推奨する着手順は **プラン2 → プラン1**。プラン2は既存のQuick Look基盤にほぼ乗るのに対し、プラン1は式ビルダーUIの作り込みが必要で規模が大きい。また「タグを付けながら整理 → 複雑な条件で抽出」という利用順とも合う。

---

## プラン1: 複雑な論理式によるファイル抽出 — `(A and B) or (C and D) or E`

### 実現性

MDQueryは入れ子の論理式をネイティブにサポートしている（`mdfind`構文そのまま）:

```
(kMDItemUserTags == 'A' && kMDItemUserTags == 'B') || kMDItemUserTags == 'E'
```

検索エンジン側の変更はほぼ不要。本質的な課題は「式のデータモデル」と「式を組み立てるUI」の2つ。

### 設計の核: 式のAST（抽象構文木）

```swift
indirect enum TagExpression: Codable, Equatable {
    case tag(String)
    case and([TagExpression])
    case or([TagExpression])
}
```

- `(A and B) or (C and D) or E` = `.or([.and([.tag("A"), .tag("B")]), .and([.tag("C"), .tag("D")]), .tag("E")])`
- **現行のシンプルモードもこのASTに統一する**（全選択タグの`.and([...])`または`.or([...])`）。`FileSearchController`の入力がAST1本になり、分岐が消える
- `Codable`にしておくことで、将来「検索条件の保存・呼び出し」がそのまま実装できる

### UI方式の選択（推奨: B案）

| 案 | 内容 | 長所/短所 |
|---|---|---|
| A. テキスト入力 | `(A and B) or C`を直接入力＋タグ名補完 | 実装小 / パーサが必要・日本語タグの引用符ルールが煩雑 |
| **B. グループビルダー** | Finderのスマートフォルダ/Mailルール風。「グループ」ごとにAND/OR切替＋タグチップ、グループの入れ子追加 | macOSの慣習に合致・パーサ不要・ASTと1:1対応 |

B案の操作フロー: 詳細検索モードに切り替えると検索条件エリアにグループが表示され、**サイドバーのタグをクリックすると「アクティブなグループ」に追加**される（現行のクリック操作の自然な拡張）。「＋グループ」でORの下にANDグループを追加。ヘッダーには`(A AND B) OR (C AND D) OR E`の可読形式を表示。

### 実装フェーズ

1. **Model** — `TagExpression`（Codable/Equatable/可読文字列化）＋単体テスト
2. **クエリ生成** — `buildQueryString(expression:)`を再帰実装（括弧付与、既存`SpotlightQuery.escapeValue`を再利用）。真理値表テスト: フィクスチャで`(Work∧Urgent)∨Personal` → File1,3,4 等を`mdfind`と突き合わせ
3. **AppState統一** — `selectedTagNames`＋`matchMode`をASTに写像（シンプルモードは従来UIのまま内部だけAST化）
4. **ExpressionBuilderView** — 再帰的なグループビュー。チップ削除・グループ削除・AND/OR切替。空グループは検索対象から除外
5. **仕上げ** — 日英ローカライズ、README、（任意）条件のUserDefaults保存

### リスクと対策

- **UIの複雑化** → 入れ子はモデル上任意深度を許すが、UIは実用上「OR直下にANDグループ」の2階層を基本形として誘導
- **NOT（除外）対応** → MDQueryにNOT演算子がなく、Spotlightでは素直に書けない。必要になったら「肯定部分をSpotlightで取得 → NOT条件をクライアント側で後段フィルタ」方式で拡張（`TagRepository`が既に全タグ付きファイルのタグ配列を保持しているため実装容易）。初期実装ではNOTを外すことを推奨

---

## プラン2: Quick Lookを見ながらタグを付与 ✅ 実装済み（2026-07-07）

> Phase 0スパイクの結果、公式API（`setResourceValue(.tagNamesKey)`）は色情報を破壊する
> （`"Name\n6"` → 読み書きラウンドトリップで `"Name\n0"` になる）ことが判明したため、
> 方式B（xattr直接編集・既存エントリの色保持）を採用した。実装は
> `Logic/FinderTagWriter.swift` / `Views/TagPaletteController.swift` /
> `Views/TagPaletteView.swift` を参照。

### 設計の核: 3つの構成要素

#### A. タグ書き込み層（現在は読み取り専用）

`ExtendedAttributeReader`の対になる`FinderTagWriter`を新設。書き込み方式は2候補あり、**Phase 0で実測して決める**（本プロジェクトの「仮説→実測」方式）:

1. **公式API**: `(url as NSURL).setResourceValue(names, forKey: .tagNamesKey)` — 簡潔だが色インデックスの扱いがブラックボックス
2. **xattr直接書き込み**: `com.apple.metadata:_kMDItemUserTags`にbinary plist（`"Name\n色番号"`配列）を書く — 兄弟プロジェクトMP4Mergerの`FFmpegRunner`に実績あり。色番号は`TagRepository`が既に持つタグ→色対応から補完

検証: フィクスチャのコピーに両方式で書き、`xattr -l`のバイト列とFinderの色表示を「Finderで手動タグ付けした場合」と比較して、一致する方を採用。

#### B. UI: フローティング・タグパレット

QLPreviewPanelはシステムUIなのでボタンを埋め込めない。代わりに**非アクティブ化パネル（NSPanel）のタグパレット**をQLパネルの横に表示する:

- 中身はSwiftUI: 既存の**FlowLayoutチップをそのまま再利用**し、現在プレビュー中のファイルに付与済みのタグはチェック付き表示。クリックでトグル
- タグ名絞り込みフィールド＋「新規タグ作成」（標準7色ピッカー付き）
- `nonactivatingPanel`スタイルにより、**クリックしてもQLパネルがキーウィンドウのまま**＝矢印キーでのファイル移動が途切れない

#### C. Quick Lookとの連携（既存資産の活用）

`QuickLookController`は既に「現在のプレビュー対象」と「リスト選択」を同期させている。ここに乗せる:

- デリゲートの`previewPanel(_:handle:)`は全キー入力を受けるので、**Tキーでパレット開閉**を転送（矢印キー転送と同じ仕組み）
- 矢印でファイルを移動するとパレットの表示対象も自動追従（`onCurrentItemChange`に接続済み）
- QLなしでも使えるよう、メインウィンドウ側にCmd+T／ツールバーボタンでも同じパレットを開く

### データ更新フロー

1. チップをクリック → **楽観的更新**（`FoundFile.tags`と`TagRepository`の件数を即時更新）→ xattr書き込み
2. 書き込み失敗（読み取り専用ボリューム、xattr非対応のexFAT等）はロールバック＋アラート
3. Spotlightの再インデックスは数秒遅れるが、モデルを先に更新しているのでUIは一貫。次回の再スキャンで自然に整合

### 実装フェーズ

0. **スパイク** — 書き込み方式2候補の実測比較（使い捨てスクリプト）
1. **FinderTagWriter** — タグ配列編集の純粋関数（追加/削除/重複排除/色保持）＋単体テスト、xattr書き込み
2. **AppState統合** — `toggle(tag:on:)`、楽観的更新＋エラーロールバック
3. **タグパレット** — NSPanel＋SwiftUIチップ、絞り込み、新規タグ作成
4. **QL連携** — Tキー転送、プレビュー追従、Cmd+T
5. **仕上げ** — 日英ローカライズ、README、（任意）Cmd+Zでのアンドゥ

### リスクと対策

- **ファイル実体への書き込み**が初の機能。テストは必ずフィクスチャのコピーで行い、削除時の挙動（タグ0個になったらxattr自体を消すか）もFinderの挙動に合わせる
- 非アクティブ化パネル内のテキストフィールド（絞り込み・新規作成）はキーフォーカスが必要 → その間だけパレットがキーになりQLに戻す制御が必要。チップのクリックだけならフォーカス移動なしで動作
