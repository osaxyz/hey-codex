# Council Protocol: Codex委譲判断基準

Claude CodeがCodex CLIに自動的に委譲するための判断基準とプロトコル。

## When to Consult (合議すべき場面)

以下の状況では `council.sh consult` を使用してCodexに意見を求める:

- **アーキテクチャ判断**: DB選定、フレームワーク選定、設計パターンの選択
- **トレードオフ不明確**: 複数アプローチがあり、メリット・デメリットが拮抗
- **セキュリティ判断**: 認証方式、暗号化方式、アクセス制御の設計
- **パフォーマンス判断**: キャッシュ戦略、インデックス設計、クエリ最適化
- **知識の限界**: Claude Codeの知識に自信がない領域（特定のフレームワーク、最新のAPI等）

### Consult実行手順

1. 相談内容をプロンプトファイルに書き出す
2. 背景情報（現在のコード構造、制約条件）を含める
3. `council.sh consult <prompt_file> <workdir>` を実行
4. Codexの回答とClaude Codeの見解を比較
5. 推奨をユーザーに報告

### Consultプロンプトテンプレート

```
## Context
[現在の状況・背景]

## Question
[具体的な質問]

## Constraints
[制約条件]

## Options Considered
[検討中の選択肢（あれば）]
```

## When to Implement (実装委譲すべき場面)

以下の状況では `council.sh implement` を使用してCodexに実装を委譲:

- **ボイラープレート生成**: CRUD、設定ファイル、テストスケルトン
- **大量コード生成**: 要件が明確で、大量のコードが必要な場合
- **パターン反復**: 既存パターンの繰り返し的な実装
- **コンテキスト節約**: コンテキストウィンドウを節約したい大きな実装

### Implement実行手順

1. 実装要件を明確にプロンプトファイルに書き出す
2. 入力/出力の仕様、ファイルパス、使用技術を明記
3. `council.sh implement <prompt_file> <workdir>` を実行
4. 変更されたファイルを確認
5. 品質チェック（型チェック、lint、テスト実行）
6. 結果を報告

### Implementプロンプトテンプレート

```
## Task
[実装タスクの説明]

## Requirements
[具体的な要件リスト]

## File Paths
[作成・変更するファイルパス]

## Tech Stack
[使用する技術スタック]

## Acceptance Criteria
[完了条件]
```

## Auto-delegation (自動委譲)

CLAUDE.md で自動委譲が有効化されている場合、Claude Codeは以下のフローで自動的にCodexに委譲する:

1. タスクを分析し、委譲基準に照らし合わせる
2. 委譲が適切と判断した場合、ユーザーに「Codexにも意見を聞きます」と通知
3. プロンプトファイルを生成
4. `council.sh` を実行
5. 結果をCodex Council Reportフォーマットで報告

## Do NOT Delegate (委譲すべきでない場面)

- 単純な修正（typo、小さなバグ修正）
- ファイルの読み取り・検索のみの作業
- ユーザーとの対話・確認作業
- 既にClaude Codeが十分な知識を持つ領域
