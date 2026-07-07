# Apple Feedback 報告資料

TagFinder開発中に発見したmacOSの問題2件の、Feedback Assistant提出用資料。

| 問題 | 報告文面 | 再現スクリプト |
|---|---|---|
| NSMetadataQueryが全クエリで0件を返す（重大・リグレッション） | [REPORT-nsmetadataquery.md](REPORT-nsmetadataquery.md) | [repro-nsmetadataquery.swift](repro-nsmetadataquery.swift) |
| .tagNamesKeyへの書き込みがタグの色情報を破壊する（データ損失・未文書化） | [REPORT-tagnames-color-loss.md](REPORT-tagnames-color-loss.md) | [repro-tagnames-color-loss.swift](repro-tagnames-color-loss.swift) |

## 提出手順

1. https://feedbackassistant.apple.com にApple IDでサインイン（またはFeedback Assistantアプリ）
2. 「新規フィードバック」→ プラットフォーム: **macOS**
3. トピックエリア:
   - NSMetadataQuery → 「Foundation」または「Spotlight」
   - tagNames → 「Files & Storage」または「Foundation」
4. REPORT-*.mdの **Title** をタイトル欄に、本文（Description以下）を説明欄に貼り付け
5. 対応する `repro-*.swift` を**添付ファイルとして追加**
6. 可能なら「sysdiagnose」の添付を求められた場合に応じる（NSMetadataQueryの方は特に有効）

## 再現確認方法（提出前の動作確認）

```sh
swift repro-nsmetadataquery.swift      # NSMetadataQuery: 0 / MDQuery: 30 等
swift repro-tagnames-color-loss.swift  # before: \n6 → after: \n0
```

どちらも2026-07-07にmacOS 26.5.1 (25F80)で再現確認済み。実行時の出力は各REPORT内の「Actual result」に記載のものと一致するはず。
