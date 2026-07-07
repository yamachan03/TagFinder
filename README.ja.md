# TagFinder

[English](README.md)

Finderで付けたタグからファイルを横断検索するmacOSアプリです。サイドバーのタグ一覧から複数タグを選んで、AND（すべてのタグを持つ）/ OR（いずれかのタグを持つ）でファイルを絞り込めます。

## 機能

- 全ローカルボリューム（外付けドライブ含む）のFinderタグを一覧表示（ファイル数付き）
- 複数タグ選択によるAND / OR絞り込み検索
- タグ名・ファイル名それぞれのインクリメンタル絞り込み
- 検索結果のファイルを選択してスペースキーでQuick Lookプレビュー（上下カーソルキーでプレビュー対象を切替）
- ダブルクリックで開く、右クリックで「Finderで表示」「パスをコピー」
- 設定（Cmd+,）: UI言語の切替（日本語/英語）と、サイドバーのタグ表示切替（件数付きリスト／タグのみの折り返しチップ表示）

## 動作要件

- macOS 15.6以降
- **フルディスクアクセス**の許可（システム設定 > プライバシーとセキュリティ > フルディスクアクセス）
  - Spotlight経由でホーム外・外付けボリュームのタグを検索するために必要です
- 検索対象のボリュームでSpotlightインデックスが有効であること

## ビルド

Xcodeで `TagFinder.xcodeproj` を開いてビルドするだけです。プロジェクトファイルは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成しているため、ファイル構成を変えた場合は `xcodegen` を再実行してください。

```sh
xcodegen                                       # プロジェクト再生成（ファイル追加時のみ）
xcodebuild -scheme TagFinder -configuration Release build
```

## 実装メモ

Spotlight検索には `NSMetadataQuery` ではなく、`mdfind` と同じ低レベルの **MDQuery C API**（`Logic/SpotlightQuery.swift`）を使っています。開発環境（macOS 26.5）では `NSMetadataQuery` がフルディスクアクセス許可済みでもすべてのクエリに対して0件を返すためです。クエリ文字列の組み立てはユニットテストでカバーしています。

## ライセンス

[MIT License](LICENSE)
